#!/usr/bin/env python3
import argparse
import fcntl
import json
import math
import os
from pathlib import Path
import plistlib
import re
import stat
import subprocess
import sys
import tempfile
import time
from urllib.parse import urlsplit
from xml.parsers.expat import ExpatError

SCENE, SCREEN, MIC = 'Meet recording', 'Meet screen', 'Meet microphone'
CONFIG = 'Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json'
ALLOWED = frozenset(('GetRecordStatus', 'GetStreamStatus', 'GetInputList',
    'GetSceneItemList', 'GetInputDefaultSettings', 'GetInputSettings',
    'GetInputPropertiesListPropertyItems', 'GetInputMute', 'GetInputVolume',
    'GetInputAudioTracks', 'GetInputAudioMonitorType', 'SetInputSettings', 'SetCurrentProgramScene',
    'StartRecord', 'StopRecord', 'GetVirtualCamStatus',
    'GetProfileParameter', 'GetOutputList', 'GetOutputSettings', 'GetCurrentProgramScene'))


class SafeError(Exception):
    pass


def config(home):
    path = Path(home) / CONFIG
    try:
        data = json.loads(path.read_text())
        port = data.get('server_port')
        password = data.get('server_password')
        if (data.get('server_enabled') is not True or data.get('auth_required') is not True
                or not isinstance(password, str) or not password
                or type(port) is not int or not 1 <= port <= 65535):
            raise SafeError('setup_required')
        return port, password
    except (OSError, ValueError, AttributeError):
        raise SafeError('setup_required') from None


def screen_locked(runner=None):
    try:
        result = (runner or subprocess.run)(['/usr/sbin/ioreg', '-n', 'Root', '-d', '1', '-a'],
                                            shell=False, capture_output=True, timeout=5)
        if result.returncode:
            return None
        stack, flags = [plistlib.loads(result.stdout)], []
        uid = os.getuid()
        while stack:
            node = stack.pop()
            if isinstance(node, dict):
                users = node.get('IOConsoleUsers')
                if isinstance(users, list):
                    for user in users:
                        if (isinstance(user, dict) and user.get('kCGSSessionUserIDKey') == uid
                                and user.get('kCGSSessionOnConsoleKey') is True):
                            flags.append(user.get('CGSSessionScreenIsLocked', False))
                stack.extend(node.values())
            elif isinstance(node, list):
                stack.extend(node)
        return flags[0] if len(flags) == 1 and type(flags[0]) is bool else None
    except (OSError, ValueError, TypeError, plistlib.InvalidFileException, ExpatError, subprocess.TimeoutExpired):
        return None


def doctor(home, lock_state=None):
    locked = (lock_state or screen_locked)()
    try:
        port, _ = config(home)
        return {'status': 'ready', 'server_enabled': True, 'auth_required': True, 'port': port,
                'connection_tested': False, 'loopback_bind_verified': False, 'screen_locked': locked}
    except SafeError:
        result = {'status': 'setup_required', 'connection_tested': False, 'screen_locked': locked}
        try:
            data = json.loads((Path(home) / CONFIG).read_text())
            for flag in ('server_enabled', 'auth_required'):
                result[flag] = data.get(flag) if type(data.get(flag)) is bool else None
        except (OSError, ValueError, AttributeError):
            pass
        return result


class Rpc:
    def __init__(self, home):
        self.home = Path(home)

    def __call__(self, kind, data=None):
        if kind not in ALLOWED:
            raise SafeError('rpc_not_allowed')
        override = os.environ.get('OBS_WEBSOCKET_URL')
        if override:
            try:
                parsed = urlsplit(override)
                if (parsed.scheme != 'ws' or parsed.hostname not in ('127.0.0.1', 'localhost', '::1')
                        or parsed.username or parsed.password or parsed.path not in ('', '/')
                        or parsed.query or parsed.fragment):
                    raise ValueError()
            except ValueError:
                raise SafeError('remote_endpoint_denied') from None
        port, password = config(self.home)
        env = {key: os.environ[key] for key in ('PATH', 'LANG') if key in os.environ}
        env.update(HOME=str(self.home), OBS_WEBSOCKET_URL=f'ws://127.0.0.1:{port}', OBS_WEBSOCKET_PASSWORD=password)
        command = [sys.executable, '-I', '-S', str(Path(__file__).parent / 'vendor/wsctl.py'),
                   'request', '--type', kind, '--data', json.dumps(data or {})]
        try:
            result = subprocess.run(command, shell=False, capture_output=True, text=True, timeout=15, env=env)
            if result.returncode:
                raise SafeError('rpc_failed')
            response = json.loads(result.stdout)
            if response.get('requestStatus', {}).get('result') is not True:
                raise SafeError('rpc_failed')
            body = response.get('responseData', {})
            if not isinstance(body, dict):
                raise SafeError('invalid_rpc_response')
            return body
        except subprocess.TimeoutExpired:
            raise SafeError('rpc_timeout') from None
        except (OSError, ValueError, AttributeError):
            raise SafeError('invalid_rpc_response') from None


class Recorder:
    def __init__(self, rpc, state_path=None, clock=time.time, sleep=time.sleep, lock_state=None):
        self.rpc, self.clock, self.sleep = rpc, clock, sleep
        self.lock_state = lock_state or screen_locked
        self.path = Path(state_path or Path.home() / '.local/state/meet-recording/session.json')

    def execute(self, command, target=None):
        lock = None
        try:
            self.path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            lock = os.open(str(self.path) + '.lock', os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
            os.fchmod(lock, 0o600)
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise SafeError('busy') from None
            if command == 'targets':
                return {'status': 'targets', 'targets': self.targets()}
            status = self.record_status()
            if command == 'status':
                return self.status(status)
            if command == 'start':
                return self.start(target, status)
            if command == 'stop':
                return self.stop(status)
            raise SafeError('invalid_command')
        except SafeError as error:
            return {'status': 'error', 'error': str(error)}
        except (OSError, ValueError, TypeError, KeyError, AttributeError):
            return {'status': 'error', 'error': 'invalid_state_or_response'}
        finally:
            if lock is not None:
                os.close(lock)

    def read(self):
        try:
            fd = os.open(self.path, os.O_RDONLY | os.O_NOFOLLOW)
            with os.fdopen(fd) as file:
                data = json.load(file)
            if not isinstance(data, dict):
                raise SafeError('invalid_state')
            return data
        except FileNotFoundError:
            return {}

    def write(self, data):
        fd, temporary = tempfile.mkstemp(dir=self.path.parent)
        try:
            with os.fdopen(fd, 'w') as file:
                json.dump(data, file)
                file.flush()
                os.fsync(file.fileno())
            os.replace(temporary, self.path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)

    def record_status(self):
        status = self.rpc('GetRecordStatus')
        if type(status.get('outputActive')) is not bool:
            raise SafeError('invalid_rpc_response')
        for key in ('outputDuration', 'outputBytes'):
            value = status.get(key)
            if type(value) not in (int, float) or not math.isfinite(value) or value < 0:
                raise SafeError('invalid_rpc_response')
        return status

    def output_identity(self):
        outputs = [item for item in self.rpc('GetOutputList')['outputs']
                   if item.get('outputActive') is True
                   and item.get('outputName') in ('simple_file_output', 'adv_file_output')]
        if len(outputs) != 1:
            raise SafeError('recording_output_unsupported')
        output = outputs[0]
        path = self.rpc('GetOutputSettings', {'outputName': output['outputName']})['outputSettings'].get('path')
        if (not isinstance(path, str) or not Path(path).is_absolute()
                or not isinstance(output.get('outputKind'), str) or not output['outputKind']):
            raise SafeError('recording_output_unsupported')
        return {'name': output['outputName'], 'kind': output['outputKind'], 'path': path}

    def time_matches(self, status, state):
        estimated = self.clock() - status['outputDuration'] / 1000
        if 'started_at' in state:
            return abs(estimated - state['started_at']) <= 3
        return state.get('requested_at', math.inf) - 3 <= estimated <= state.get('latest_start_at', -math.inf) + 3

    def owned(self, status, state):
        if (not status['outputActive'] or state.get('phase') not in ('pending', 'recording', 'stopping')
                or not state.get('identity') or not self.time_matches(status, state)):
            return False
        return self.output_identity() == state['identity']

    def other_outputs_idle(self):
        if self.rpc('GetStreamStatus').get('outputActive') is not False:
            raise SafeError('streaming_active')
        if self.rpc('GetVirtualCamStatus').get('outputActive') is not False:
            raise SafeError('other_output_active')
        outputs = self.rpc('GetOutputList').get('outputs')
        if (not isinstance(outputs, list) or any(not isinstance(item, dict)
                or type(item.get('outputActive')) is not bool for item in outputs)):
            raise SafeError('invalid_rpc_response')
        if any(item['outputActive'] for item in outputs):
            raise SafeError('other_output_active')

    def parameter(self, category, name):
        result = self.rpc('GetProfileParameter', {'parameterCategory': category, 'parameterName': name})
        value = result.get('parameterValue')
        return result.get('defaultParameterValue') if value is None else value

    def recording_profile(self):
        mode = self.parameter('Output', 'Mode')
        if mode not in ('Simple', 'Advanced'):
            raise SafeError('recording_profile_unsupported')
        category = 'SimpleOutput' if mode == 'Simple' else 'AdvOut'
        if mode == 'Simple' and self.parameter(category, 'RecQuality') not in ('Small', 'HQ'):
            raise SafeError('recording_profile_unsupported')
        if mode == 'Advanced' and self.parameter(category, 'RecType') != 'Standard':
            raise SafeError('recording_profile_unsupported')
        overwrite = self.parameter('Output', 'OverwriteIfExists')
        split = self.parameter(category, 'RecSplitFile') if mode == 'Advanced' else None
        fmt = self.parameter(category, 'RecFormat2')
        if (overwrite not in (None, 'false', '0', False) or split not in (None, 'false', '0', False)
                or not isinstance(fmt, str) or not fmt or fmt.lower() == 'flv'):
            raise SafeError('recording_profile_unsupported')
        try:
            tracks = int(self.parameter(category, 'RecTracks'))
            if not 1 <= tracks <= 63:
                raise ValueError()
        except (ValueError, TypeError):
            raise SafeError('recording_profile_unsupported') from None
        return tracks, 'simple_file_output' if mode == 'Simple' else 'adv_file_output'

    def targets(self):
        response = self.rpc('GetInputPropertiesListPropertyItems', {'inputName': SCREEN, 'propertyName': 'window'})
        return [{'id': item['itemValue'], 'title': item['itemName']}
                for item in response['propertyItems']
                if item.get('itemEnabled') is True and type(item.get('itemValue')) is int
                and isinstance(item.get('itemName'), str)
                and re.search(r'\bMeet\b', item['itemName'], re.I)
                and re.search(r'\b[a-z]{3}-[a-z]{4}-[a-z]{3}\b', item['itemName'])]

    def verify(self, recorded_tracks):
        inputs = {item['inputName']: item['inputKind'] for item in self.rpc('GetInputList')['inputs']}
        if inputs.get(SCREEN) != 'screen_capture' or inputs.get(MIC) != 'coreaudio_input_capture':
            raise SafeError('sources_configuration_invalid')
        items = self.rpc('GetSceneItemList', {'sceneName': SCENE})['sceneItems']
        if (len(items) != 2 or {item['sourceName'] for item in items} != {SCREEN, MIC}
                or any(item.get('sceneItemEnabled') is not True or item.get('isGroup') for item in items)):
            raise SafeError('scene_configuration_invalid')
        settings = self.rpc('GetInputDefaultSettings', {'inputKind': 'screen_capture'})['defaultInputSettings']
        settings.update(self.rpc('GetInputSettings', {'inputName': SCREEN})['inputSettings'])
        if settings.get('type') != 1:
            raise SafeError('window_capture_required')
        for name in (SCREEN, MIC):
            data = {'inputName': name}
            muted = self.rpc('GetInputMute', data).get('inputMuted')
            volume = self.rpc('GetInputVolume', data).get('inputVolumeMul')
            tracks = self.rpc('GetInputAudioTracks', data).get('inputAudioTracks')
            monitor = self.rpc('GetInputAudioMonitorType', data).get('monitorType')
            if (muted is not False or type(volume) not in (float, int) or not math.isfinite(volume)
                    or volume <= 0 or not isinstance(tracks, dict)
                    or monitor not in ('OBS_MONITORING_TYPE_NONE', 'OBS_MONITORING_TYPE_MONITOR_AND_OUTPUT')
                    or not any(tracks.get(str(index + 1)) is True and recorded_tracks & (1 << index)
                               for index in range(6))):
                raise SafeError('audio_configuration_invalid')

    def verify_target(self, selected):
        settings = self.rpc('GetInputDefaultSettings', {'inputKind': 'screen_capture'})['defaultInputSettings']
        settings.update(self.rpc('GetInputSettings', {'inputName': SCREEN})['inputSettings'])
        scene = self.rpc('GetCurrentProgramScene').get('currentProgramSceneName')
        if (settings.get('type') != 1 or settings.get('window') != selected or scene != SCENE
                or selected not in [item['id'] for item in self.targets()]):
            raise SafeError('capture_target_changed')

    def start(self, target, status):
        state = self.read()
        if state.get('phase') == 'disputed':
            raise SafeError('previous_save_disputed')
        if status['outputActive']:
            return {'status': 'already_recording', 'owned': self.owned(status, state), 'recording_confirmed': False}
        locked = self.lock_state()
        if locked is not False:
            raise SafeError('screen_locked' if locked is True else 'screen_lock_unknown')
        if state.get('phase') == 'stopping' and not self.saved(state)['saved']:
            raise SafeError('previous_save_pending')
        self.other_outputs_idle()
        recorded_tracks, output_name = self.recording_profile()
        self.verify(recorded_tracks)
        selected = next((item['id'] for item in self.targets() if str(item['id']) == str(target)), None)
        if selected is None:
            raise SafeError('invalid_target')
        if self.record_status()['outputActive']:
            raise SafeError('output_became_active')
        self.other_outputs_idle()
        self.rpc('SetInputSettings', {'inputName': SCREEN, 'inputSettings': {'type': 1, 'window': selected}, 'overlay': True})
        self.rpc('SetCurrentProgramScene', {'sceneName': SCENE})
        self.verify_target(selected)
        state = {'phase': 'pending', 'requested_at': self.clock(), 'latest_start_at': self.clock() + 15}
        self.write(state)
        error = None
        try:
            self.rpc('StartRecord')
        except SafeError as caught:
            state['phase'] = 'uncertain'
            self.write(state)
            return {'status': 'unconfirmed', 'error': str(caught), 'recording_confirmed': False,
                    'owned': False, 'recording_may_be_active': True, 'ownership_uncertain': True}
        previous = None
        try:
            for _ in range(8):
                current = self.record_status()
                if current['outputActive'] and self.time_matches(current, state):
                    if not state.get('identity'):
                        identity = self.output_identity()
                        if identity['name'] != output_name:
                            raise SafeError('recording_output_unsupported')
                        state.update(identity=identity, output_path=identity['path'])
                        self.write(state)
                    if not self.owned(current, state):
                        raise SafeError('recording_not_owned')
                    if (previous and current['outputDuration'] > previous['outputDuration']
                            and current['outputBytes'] > previous['outputBytes']):
                        self.verify_target(selected)
                        state.update(phase='recording', started_at=self.clock() - current['outputDuration'] / 1000)
                        self.write(state)
                        return {'status': 'recording', 'owned': True, 'recording_confirmed': True,
                                'audio_configuration_verified': True, 'actual_audio_verified': False}
                    previous = current
                self.sleep(0.5)
        except SafeError as caught:
            error = str(caught)
        result = {'status': 'unconfirmed', 'recording_confirmed': False, 'ownership_pending': True}
        if error:
            result['error'] = error
        return result

    def saved(self, state):
        if state.get('phase') == 'disputed':
            return {'saved': False, 'save_disputed': True}
        path = state.get('output_path')
        if isinstance(path, str) and path:
            try:
                info = Path(path).lstat()
                if stat.S_ISREG(info.st_mode) and info.st_size > 0:
                    return {'saved': True, 'path': path, 'size': info.st_size}
            except OSError:
                pass
        return {'saved': False, 'save_pending': True}

    def status(self, status):
        state = self.read()
        result = {'status': 'recording' if status['outputActive'] else 'inactive',
                  'active': status['outputActive'], 'owned': self.owned(status, state),
                  'duration_ms': status['outputDuration'], 'bytes': status['outputBytes'],
                  'screen_locked': self.lock_state()}
        if state.get('phase') == 'disputed':
            result.update(self.saved(state))
        elif state.get('phase') == 'stopping' and not status['outputActive']:
            result.update(self.saved(state))
        return result

    def stop(self, status):
        state = self.read()
        if not status['outputActive']:
            return self.status(status)
        if not self.owned(status, state):
            raise SafeError('recording_not_owned')
        state.update(phase='stopping', output_path=state['identity']['path'])
        self.write(state)
        error = None
        try:
            response = self.rpc('StopRecord')
            if response.get('outputPath') != state['output_path']:
                state.update(phase='disputed', reported_path=response.get('outputPath'))
                self.write(state)
                return {'status': 'save_disputed', 'error': 'output_path_mismatch',
                        'saved': False, 'save_disputed': True}
        except SafeError as caught:
            error = str(caught)
        try:
            for _ in range(8):
                if not self.record_status()['outputActive']:
                    result = self.saved(state)
                    if result['saved']:
                        return {'status': 'stopped', **result}
                self.sleep(0.5)
        except SafeError as caught:
            error = str(caught)
        return {'status': 'stop_unconfirmed', 'saved': False, 'save_pending': True,
                **({'error': error} if error else {})}


def main():
    parser = argparse.ArgumentParser(description='Record a Google Meet window and system audio plus microphone with local OBS. All results are JSON; audio checks verify configuration only.')
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('doctor', help='Inspect local OBS websocket config offline; no connection or bind test.')
    commands.add_parser('targets', help='List current enabled Meet windows with meeting codes.')
    start = commands.add_parser('start', help='Validate the dedicated scene and audio, select a current window, and confirm output progress.')
    start.add_argument('--target-id', required=True, help='ID from a fresh targets listing.')
    commands.add_parser('status', help='Report recording ownership or recheck a pending saved file.')
    commands.add_parser('stop', help='Stop only this helper\'s recording; verify a nonempty saved file.')
    args = parser.parse_args()
    if args.command == 'doctor':
        result = doctor(Path.home())
    else:
        result = Recorder(Rpc(Path.home())).execute(args.command, getattr(args, 'target_id', None))
    print(json.dumps(result, ensure_ascii=False))
    return 1 if result.get('status') in ('error', 'setup_required', 'unconfirmed', 'stop_unconfirmed', 'save_disputed') else 0


if __name__ == '__main__':
    sys.exit(main())
