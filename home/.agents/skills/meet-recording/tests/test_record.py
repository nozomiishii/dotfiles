import importlib.util
import contextlib
import io
import plistlib
import fcntl
import sys
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('record', Path(__file__).parents[1] / 'scripts/record.py')
record = importlib.util.module_from_spec(spec)
spec.loader.exec_module(record)


class Obs:
    def __init__(self):
        self.active = False
        self.progress = True
        self.duration = 0
        self.bytes = 0
        self.target = 42
        self.muted = False
        self.capture_audio = True
        self.volume = 1
        self.tracks = {'1': True}
        self.monitoring = {name: {'monitorType': 'OBS_MONITORING_TYPE_NONE'}
                           for name in ('Meet screen', 'Meet microphone')}
        self.calls = []
        self.path = ''
        self.start_error = False
        self.stream = False
        self.virtual = False
        self.replay = False
        self.scene = 'Other scene'
        self.ignore_target = False
        self.ignore_scene = False
        self.stop_timeout = False
        self.output_name = 'simple_file_output'
        self.output_kind = 'ffmpeg_muxer'
        self.profiles = {('Output', 'Mode'): 'Simple', ('SimpleOutput', 'RecQuality'): 'Small',
                         ('SimpleOutput', 'RecTracks'): '1', ('SimpleOutput', 'RecFormat2'): 'hybrid_mov',
                         ('Output', 'OverwriteIfExists'): 'false', ('AdvOut', 'RecType'): 'Standard',
                         ('AdvOut', 'RecTracks'): '1', ('AdvOut', 'RecSplitFile'): 'false',
                         ('AdvOut', 'RecFormat2'): 'hybrid_mov'}

    def __call__(self, kind, data=None):
        data = data or {}
        self.calls.append((kind, data))
        if kind == 'GetRecordStatus':
            if self.active and self.progress:
                self.duration += 500
                self.bytes += 1024
            return {'outputActive': self.active, 'outputPaused': False, 'outputDuration': self.duration, 'outputBytes': self.bytes}
        if kind == 'GetVirtualCamStatus':
            return {'outputActive': self.virtual}
        if kind == 'GetReplayBufferStatus':
            return {'outputActive': self.replay}
        if kind == 'GetProfileParameter':
            value = self.profiles[(data['parameterCategory'], data['parameterName'])]
            return {'parameterValue': value, 'defaultParameterValue': value}
        if kind == 'GetOutputList':
            return {'outputs': [{'outputName': self.output_name, 'outputKind': self.output_kind,
                                 'outputActive': self.active},
                                {'outputName': 'replay_buffer', 'outputKind': 'replay_buffer',
                                 'outputActive': self.replay}]}
        if kind == 'GetOutputSettings':
            return {'outputSettings': {'path': self.path}}
        if kind == 'GetCurrentProgramScene':
            return {'currentProgramSceneName': self.scene}
        if kind == 'GetStreamStatus':
            return {'outputActive': self.stream}
        if kind == 'GetInputList':
            return {'inputs': [{'inputName': 'Meet screen', 'inputKind': 'screen_capture'}, {'inputName': 'Meet microphone', 'inputKind': 'coreaudio_input_capture'}]}
        if kind == 'GetSceneItemList':
            return {'sceneItems': [{'sourceName': 'Meet screen', 'sceneItemEnabled': True, 'isGroup': False}, {'sourceName': 'Meet microphone', 'sceneItemEnabled': True, 'isGroup': False}]}
        if kind == 'GetInputDefaultSettings':
            return {'defaultInputSettings': {'capture_audio': True, 'type': 1}}
        if kind == 'GetInputSettings':
            return {'inputKind': 'screen_capture', 'inputSettings': {'type': 1, 'window': self.target, 'capture_audio': self.capture_audio}}
        if kind == 'GetInputPropertiesListPropertyItems':
            return {'propertyItems': [{'itemName': '[Google Chrome] Google Meet - abc-defg-hij', 'itemValue': 42, 'itemEnabled': True}, {'itemName': '[Safari] Inbox', 'itemValue': 87, 'itemEnabled': True}]}
        if kind == 'GetInputMute':
            return {'inputMuted': self.muted}
        if kind == 'GetInputVolume':
            return {'inputVolumeMul': self.volume, 'inputVolumeDb': 0}
        if kind == 'GetInputAudioTracks':
            return {'inputAudioTracks': self.tracks}
        if kind == 'GetInputAudioMonitorType':
            return self.monitoring[data['inputName']]
        if kind == 'SetInputSettings':
            if not self.ignore_target:
                self.target = data['inputSettings']['window']
            return {}
        if kind == 'SetCurrentProgramScene':
            if not self.ignore_scene:
                self.scene = data['sceneName']
            return {}
        if kind == 'StartRecord':
            self.active = True
            if self.start_error:
                raise record.SafeError('transport_error')
            return {}
        if kind == 'StopRecord':
            self.active = False
            if self.stop_timeout:
                raise record.SafeError('rpc_timeout')
            return {'outputPath': self.path}
        raise AssertionError(kind)


class RecorderTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.state = Path(self.tmp.name) / 'state/session.json'
        self.obs = Obs()
        self.obs.path = str(Path(self.tmp.name) / 'meeting.mkv')
        self.now = 1000.
        self.rec = record.Recorder(self.obs, state_path=self.state, clock=lambda: self.now, sleep=self.sleep, lock_state=lambda: False)

    def sleep(self, seconds):
        self.now += seconds

    def start(self):
        return self.rec.execute('start', '42')

    def test_増加する出力を確認してから録画成功を返す(self):
        result = self.start()
        self.assertTrue(result['recording_confirmed'])
        self.assertTrue(result['owned'])
        self.assertEqual(stat.S_IMODE(self.state.stat().st_mode), 0o600)

    def test_開始応答だけでは録画成功にしない(self):
        self.obs.progress = False
        result = self.start()
        self.assertFalse(result['recording_confirmed'])
        self.assertTrue(self.state.exists())
        self.assertFalse(any(k == 'StopRecord' for k, _ in self.obs.calls))

    def test_録画中の再開始ではシーンと対象を変更しない(self):
        self.obs.active = True
        result = self.start()
        self.assertEqual(result['status'], 'already_recording')
        self.assertFalse(any(k.startswith('Set') or k == 'StartRecord' for k, _ in self.obs.calls))

    def test_最新候補にない対象では開始しない(self):
        result = self.rec.execute('start', '87')
        self.assertEqual(result['error'], 'invalid_target')
        self.assertFalse(self.obs.active)

    def test_候補一覧は会議コード付きMeetだけを返す(self):
        result = self.rec.execute('targets')
        self.assertEqual(result['targets'], [{'id': 42, 'title': '[Google Chrome] Google Meet - abc-defg-hij'}])

    def test_音声設定が無効なら開始しない(self):
        for field, value in [('muted', True), ('volume', 0), ('tracks', {'1': False})]:
            with self.subTest(field=field):
                setattr(self.obs, field, value)
                result = self.start()
                self.assertEqual(result['error'], 'audio_configuration_invalid')
                self.assertFalse(self.obs.active)
                setattr(self.obs, field, {'muted': False, 'capture_audio': True, 'volume': 1, 'tracks': {'1': True}}[field])

    def test_モニター専用の音源では設定を変更せず録画を拒否する(self):
        for name in ('Meet screen', 'Meet microphone'):
            with self.subTest(name=name):
                obs = Obs()
                obs.path = self.obs.path
                obs.monitoring[name] = {'monitorType': 'OBS_MONITORING_TYPE_MONITOR_ONLY'}
                self.rec.rpc = obs
                self.assertEqual(self.start(), {'status': 'error', 'error': 'audio_configuration_invalid'})
                self.assertFalse(obs.active)
                self.assertFalse(any(kind.startswith('Set') or kind == 'StartRecord' for kind, _ in obs.calls))

    def test_不明なモニター設定の音源では設定を変更せず録画を拒否する(self):
        responses = [{}, {'monitorType': None}, {'monitorType': ''}, {'monitorType': 'unknown'},
                     {'monitorType': False}, {'monitorType': 0}, {'monitorType': []}, {'monitorType': {}}]
        for name in ('Meet screen', 'Meet microphone'):
            for response in responses:
                with self.subTest(name=name, response=response):
                    obs = Obs()
                    obs.path = self.obs.path
                    obs.monitoring[name] = response
                    self.rec.rpc = obs
                    self.assertEqual(self.start(), {'status': 'error', 'error': 'audio_configuration_invalid'})
                    self.assertFalse(obs.active)
                    self.assertFalse(any(kind.startswith('Set') or kind == 'StartRecord' for kind, _ in obs.calls))

    def test_出力を残すモニター設定なら両方の音源で録画できる(self):
        for name in ('Meet screen', 'Meet microphone'):
            for monitor_type in ('OBS_MONITORING_TYPE_NONE', 'OBS_MONITORING_TYPE_MONITOR_AND_OUTPUT'):
                with self.subTest(name=name, monitor_type=monitor_type):
                    obs = Obs()
                    obs.path = self.obs.path
                    obs.monitoring[name] = {'monitorType': monitor_type}
                    self.rec.rpc = obs
                    result = self.start()
                    self.assertTrue(result.get('recording_confirmed'))
                    self.assertTrue(result.get('audio_configuration_verified'))

    def test_配信中は対象を変更しない(self):
        self.obs.stream = True
        result = self.start()
        self.assertEqual(result['error'], 'streaming_active')
        self.assertFalse(any(k.startswith('Set') for k, _ in self.obs.calls))

    def test_所有情報がない録画は停止しない(self):
        self.obs.active = True
        result = self.rec.execute('stop')
        self.assertEqual(result['error'], 'recording_not_owned')
        self.assertTrue(self.obs.active)

    def test_古い所有情報で別の録画を停止しない(self):
        self.start()
        self.now += 600
        self.obs.duration = 0
        result = self.rec.execute('stop')
        self.assertEqual(result['error'], 'recording_not_owned')
        self.assertTrue(self.obs.active)

    def test_開始応答が失敗した録画の所有権を自動取得しない(self):
        self.obs.start_error = True
        self.obs.progress = False
        result = self.start()
        self.assertFalse(result['recording_confirmed'])
        self.assertTrue(self.state.exists())
        self.assertFalse(self.rec.execute('status')['owned'])
        self.assertEqual(self.rec.execute('stop').get('error'), 'recording_not_owned')
        self.assertTrue(self.obs.active)

    def test_実在する空でないファイルだけ保存済みにする(self):
        self.start()
        output = Path(self.tmp.name) / 'meeting.mkv'
        output.write_bytes(b'actual video fixture')
        self.obs.path = str(output)
        result = self.rec.execute('stop')
        self.assertTrue(result['saved'])
        self.assertEqual(result['path'], str(output))
        self.assertEqual(result['size'], 20)

    def test_未確定ファイルは保留してstatusで再確認する(self):
        self.start()
        output = Path(self.tmp.name) / 'meeting.mkv'
        self.obs.path = str(output)
        result = self.rec.execute('stop')
        self.assertFalse(result['saved'])
        output.write_bytes(b'finalized')
        self.assertTrue(self.rec.execute('status')['saved'])

    def test_空ファイルとディレクトリを保存成功にしない(self):
        output = Path(self.tmp.name) / 'empty.mkv'
        self.obs.path = str(output)
        self.start()
        output.touch()
        self.obs.path = str(output)
        self.assertFalse(self.rec.execute('stop')['saved'])
        output.unlink()
        output.mkdir()
        self.assertFalse(self.rec.execute('status')['saved'])

    def test_録画していなければ停止要求しない(self):
        result = self.rec.execute('stop')
        self.assertEqual(result['status'], 'inactive')
        self.assertFalse(any(k == 'StopRecord' for k, _ in self.obs.calls))

    def test_別プロセスが操作中なら録画を変更しない(self):
        self.state.parent.mkdir()
        with open(str(self.state) + '.lock', 'w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.assertEqual(self.start()['error'], 'busy')
        self.assertFalse(self.obs.active)

    def test_有効な開始応答でも録画が非activeなら成功しない(self):
        original = self.obs.__call__
        def boundary(kind, data=None):
            if kind == 'StartRecord':
                return {}
            return original(kind, data)
        self.rec.rpc = boundary
        self.assertFalse(self.start()['recording_confirmed'])
        self.assertTrue(self.state.exists())

    def test_保存パスがシンボリックリンクなら成功にしない(self):
        self.obs.path = str(Path(self.tmp.name) / 'recording.mkv')
        self.start()
        existing = Path(self.tmp.name) / 'existing.txt'
        existing.write_text('unrelated data')
        output = Path(self.tmp.name) / 'recording.mkv'
        output.symlink_to(existing)
        self.obs.path = str(output)
        self.assertFalse(self.rec.execute('stop')['saved'])


    def test_直後に始まった手動録画を所有済みと扱わない(self):
        self.start()
        self.obs.duration = 0
        self.obs.path = str(Path(self.tmp.name) / 'manual-recording.mkv')
        self.assertFalse(self.rec.execute('status')['owned'])
        result = self.rec.execute('stop')
        self.assertEqual(result.get('error'), 'recording_not_owned')
        self.assertTrue(self.obs.active)

    def test_録画開始後は同じパスでも出力の種類変更を拒否する(self):
        self.start()
        self.obs.output_kind = 'ffmpeg_output'
        self.assertEqual(self.rec.execute('stop').get('error'), 'recording_not_owned')
        self.assertTrue(self.obs.active)

    def test_仮想カメラとリプレイ中は画面を変更しない(self):
        for field in ('virtual', 'replay'):
            with self.subTest(field=field):
                setattr(self.obs, field, True)
                self.assertEqual(self.start().get('error'), 'other_output_active')
                self.assertFalse(any(kind.startswith('Set') for kind, _ in self.obs.calls))
                setattr(self.obs, field, False)

    def test_録画トラックと音源トラックが交わらなければ開始しない(self):
        self.obs.tracks = {'1': False, '2': True}
        self.assertEqual(self.start().get('error'), 'audio_configuration_invalid')
        self.assertFalse(self.obs.active)

    def test_録画プロファイルの危険な設定を開始前に拒否する(self):
        for key, value in [(('SimpleOutput', 'RecQuality'), 'Stream'),
                           (('SimpleOutput', 'RecQuality'), 'Lossless'),
                           (('SimpleOutput', 'RecFormat2'), 'flv'),
                           (('Output', 'OverwriteIfExists'), 'true')]:
            with self.subTest(key=key, value=value):
                original = self.obs.profiles[key]
                self.obs.profiles[key] = value
                self.assertEqual(self.start().get('error'), 'recording_profile_unsupported')
                self.assertFalse(self.obs.active)
                self.obs.profiles[key] = original

    def test_Advanced録画トラックも検証する(self):
        self.obs.profiles[('Output', 'Mode')] = 'Advanced'
        self.obs.profiles[('AdvOut', 'RecSplitFile')] = 'true'
        self.assertEqual(self.start().get('error'), 'recording_profile_unsupported')
        self.obs.profiles[('AdvOut', 'RecSplitFile')] = 'false'
        self.obs.profiles[('AdvOut', 'RecTracks')] = '2'
        self.obs.output_name = 'adv_file_output'
        self.assertEqual(self.start().get('error'), 'audio_configuration_invalid')
        self.obs.tracks = {'1': False, '2': True}
        self.assertTrue(self.start().get('recording_confirmed'))

    def test_録画プロファイルの未設定値は既定値を使う(self):
        original = self.obs.__call__
        def boundary(kind, data=None):
            response = original(kind, data)
            if kind == 'GetProfileParameter':
                response['parameterValue'] = None
            return response
        self.rec.rpc = boundary
        self.assertTrue(self.start().get('recording_confirmed'))

    def test_停止がタイムアウトしても保存先を回復する(self):
        self.start()
        self.obs.stop_timeout = True
        self.rec.execute('stop')
        Path(self.obs.path).write_bytes(b'finalized recording')
        result = self.rec.execute('status')
        self.assertTrue(result.get('saved'))
        self.assertEqual(result.get('path'), self.obs.path)

    def test_設定応答が成功でも対象が変わらなければ録画しない(self):
        self.obs.target = 87
        self.obs.ignore_target = True
        self.assertEqual(self.start().get('error'), 'capture_target_changed')
        self.assertFalse(self.obs.active)

    def test_設定応答が成功でも別シーンなら録画しない(self):
        self.obs.ignore_scene = True
        self.assertEqual(self.start().get('error'), 'capture_target_changed')
        self.assertFalse(self.obs.active)

    def test_録画開始後に対象が変わったら成功と報告しない(self):
        original = self.obs.__call__
        def boundary(kind, data=None):
            response = original(kind, data)
            if kind == 'StartRecord':
                self.obs.target = 87
            return response
        self.rec.rpc = boundary
        self.assertFalse(self.start().get('recording_confirmed'))
        self.assertTrue(self.obs.active)
        self.assertTrue(self.rec.execute('status')['owned'])


    def test_開始拒否の直前に始まった手動録画を引き取らない(self):
        original = self.obs.__call__
        def boundary(kind, data=None):
            if kind == 'StartRecord':
                self.obs.active = True
                self.obs.path = str(Path(self.tmp.name) / 'manually_started.mkv')
                raise record.SafeError('rpc_failed')
            return original(kind, data)
        self.rec.rpc = boundary
        result = self.start()
        self.assertFalse(result.get('recording_confirmed'))
        self.assertFalse(self.rec.execute('status')['owned'])
        self.assertEqual(self.rec.execute('stop').get('error'), 'recording_not_owned')
        self.assertTrue(self.obs.active)

    def test_停止応答の保存先が矛盾したら後からも成功にしない(self):
        self.start()
        Path(self.obs.path).write_bytes(b'known recording')
        original = self.obs.__call__
        def boundary(kind, data=None):
            response = original(kind, data)
            if kind == 'StopRecord':
                response['outputPath'] = str(Path(self.tmp.name) / 'other-recording.mkv')
            return response
        self.rec.rpc = boundary
        self.assertFalse(self.rec.execute('stop').get('saved'))
        self.assertFalse(self.rec.execute('status').get('saved'))
        self.assertFalse(self.rec.execute('stop').get('saved'))
        self.assertEqual(self.start().get('error'), 'previous_save_disputed')
        self.assertFalse(self.obs.active)


    def test_未設定のリプレイ状態APIが失敗しても停止中なら開始できる(self):
        original = self.obs.__call__
        def boundary(kind, data=None):
            if kind == 'GetReplayBufferStatus':
                raise record.SafeError('rpc_failed')
            return original(kind, data)
        self.rec.rpc = boundary
        self.assertTrue(self.start().get('recording_confirmed'))

    def test_出力一覧にアクティブなリプレイがあれば設定を変更しない(self):
        original = self.obs.__call__
        def boundary(kind, data=None):
            if kind == 'GetReplayBufferStatus':
                raise record.SafeError('rpc_failed')
            return original(kind, data)
        self.rec.rpc = boundary
        self.obs.replay = True
        self.assertEqual(self.start().get('error'), 'other_output_active')
        self.assertFalse(self.obs.active)
        self.assertFalse(any(kind.startswith('Set') for kind, _ in self.obs.calls))

    def test_出力一覧の不明なアクティブ状態では設定を変更しない(self):
        original = self.obs.__call__
        for flag in (None, 0, 'false', 'true'):
            with self.subTest(flag=flag):
                def boundary(kind, data=None):
                    if kind == 'GetOutputList':
                        return {'outputs': [{'outputName': 'unknown_output', 'outputKind': 'other', 'outputActive': flag}]}
                    return original(kind, data)
                self.rec.rpc = boundary
                self.assertEqual(self.start().get('error'), 'invalid_rpc_response')
                self.assertFalse(self.obs.active)
                self.assertFalse(any(kind.startswith('Set') for kind, _ in self.obs.calls))


    def test_画面ロック中と不明な状態では新しい録画を始めない(self):
        for locked, error in [(True, 'screen_locked'), (None, 'screen_lock_unknown')]:
            with self.subTest(locked=locked):
                self.rec.lock_state = lambda: locked
                self.assertEqual(self.start().get('error'), error)
                self.assertFalse(self.obs.active)
                self.assertFalse(any(kind.startswith('Set') for kind, _ in self.obs.calls))

    def test_録画中に画面ロックしても状態報告だけを行う(self):
        self.start()
        self.rec.lock_state = lambda: True
        result = self.rec.execute('status')
        self.assertIs(result.get('screen_locked'), True)
        self.assertTrue(self.obs.active)
        self.assertTrue(result['owned'])
        self.assertFalse(any(kind == 'StopRecord' for kind, _ in self.obs.calls))



class TransportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.cfg = self.home / 'Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json'
        self.cfg.parent.mkdir(parents=True)
        self.cfg.write_text(json.dumps({'server_enabled': True, 'auth_required': True, 'server_password': 'fixture-secret', 'server_port': 4455}))
        self.env = patch.dict(os.environ, {'HOME': str(self.home)}, clear=True)
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_doctorはネットワークを呼ばず秘密を出さない(self):
        with patch.object(subprocess, 'run', side_effect=AssertionError('network forbidden')):
            result = record.doctor(self.home, lock_state=lambda: False)
        self.assertEqual(result['status'], 'ready')
        self.assertNotIn('fixture-secret', json.dumps(result))

    def test_設定不足と認証無効をsetup_requiredにする(self):
        for data in [{}, {'server_enabled': True, 'auth_required': False}]:
            self.cfg.write_text(json.dumps(data))
            self.assertEqual(record.doctor(self.home, lock_state=lambda: False)['status'], 'setup_required')
        self.cfg.unlink()
        self.assertEqual(record.doctor(self.home, lock_state=lambda: False)['status'], 'setup_required')

    def test_リモートURLは接続前に拒否する(self):
        os.environ['OBS_WEBSOCKET_URL'] = 'ws://example.com:4455'
        with patch.object(subprocess, 'run', side_effect=AssertionError('network forbidden')):
            with self.assertRaises(record.SafeError) as caught:
                record.Rpc(self.home)('GetRecordStatus')
        self.assertEqual(str(caught.exception), 'remote_endpoint_denied')

    def test_子プロセスに最小環境だけを渡して応答を検証する(self):
        os.environ['SECRET_OTHER'] = 'do-not-inherit'
        def runner(command, **kwargs):
            self.assertEqual(command[1:3], ['-I', '-S'])
            self.assertFalse(kwargs.get('shell', False))
            self.assertEqual(kwargs['timeout'], 15)
            self.assertEqual(kwargs['env']['OBS_WEBSOCKET_URL'], 'ws://127.0.0.1:4455')
            self.assertNotIn('SECRET_OTHER', kwargs['env'])
            return subprocess.CompletedProcess(command, 0, json.dumps({'requestStatus': {'result': True, 'code': 100}, 'responseData': {'outputActive': False}}), '')
        with patch.object(subprocess, 'run', side_effect=runner):
            self.assertEqual(record.Rpc(self.home)('GetRecordStatus'), {'outputActive': False})

    def test_失敗応答やstderrを利用者に漏らさない(self):
        cases = [subprocess.CompletedProcess([], 1, '', 'fixture-secret'), subprocess.CompletedProcess([], 0, '{bad fixture-secret', ''), subprocess.CompletedProcess([], 0, json.dumps({'requestStatus': {'result': False, 'comment': 'fixture-secret'}}), '')]
        for outcome in cases:
            with self.subTest(outcome=outcome.returncode), patch.object(subprocess, 'run', return_value=outcome):
                with self.assertRaises(record.SafeError) as caught:
                    record.Rpc(self.home)('GetRecordStatus')
                self.assertNotIn('fixture-secret', str(caught.exception))

    def test_任意のRPCを許可しない(self):
        with self.assertRaises(record.SafeError):
            record.Rpc(self.home)('StartStream')

    def test_音声モニター設定は取得だけ許可する(self):
        data = {'inputName': 'Meet microphone'}
        response = {'monitorType': 'OBS_MONITORING_TYPE_NONE'}
        def runner(command, **kwargs):
            self.assertEqual(command[command.index('--type') + 1], 'GetInputAudioMonitorType')
            self.assertEqual(json.loads(command[command.index('--data') + 1]), data)
            return subprocess.CompletedProcess(command, 0, json.dumps({
                'requestStatus': {'result': True, 'code': 100}, 'responseData': response}), '')
        with patch.object(subprocess, 'run', side_effect=runner):
            try:
                result = record.Rpc(self.home)('GetInputAudioMonitorType', data)
            except record.SafeError as error:
                self.fail(str(error))
            self.assertEqual(result, response)
            with self.assertRaises(record.SafeError) as caught:
                record.Rpc(self.home)('SetInputAudioMonitorType', {**data, **response})
            self.assertEqual(str(caught.exception), 'rpc_not_allowed')

    def test_doctorは無効化されているフラグを明示する(self):
        self.cfg.write_text(json.dumps({'server_enabled': False, 'auth_required': True, 'server_password': 'fixture-secret', 'server_port': 4455}))
        result = record.doctor(self.home, lock_state=lambda: False)
        self.assertEqual(result['status'], 'setup_required')
        self.assertIs(result.get('server_enabled'), False)
        self.assertIs(result.get('auth_required'), True)
        self.assertNotIn('fixture-secret', json.dumps(result))

    def test_CLIのdoctorとhelpを偽HOMEで実行する(self):
        script = str(Path(__file__).parents[1] / 'scripts/record.py')
        output = io.StringIO()
        with patch.object(sys, 'argv', [script, 'doctor']), patch.object(record, 'screen_locked', return_value=False), contextlib.redirect_stdout(output):
            self.assertEqual(record.main(), 0)
        self.assertEqual(json.loads(output.getvalue())['status'], 'ready')
        self.assertNotIn('fixture-secret', output.getvalue())
        help_result = subprocess.run([sys.executable, script, '--help'], env=dict(os.environ), capture_output=True, text=True)
        self.assertEqual(help_result.returncode, 0)
        self.assertIn('targets', help_result.stdout)
        self.assertIn('stop', help_result.stdout)

    def test_タイムアウトを秘密なしで通知する(self):
        with patch.object(subprocess, 'run', side_effect=subprocess.TimeoutExpired(['fixture-secret'], 15)):
            with self.assertRaises(record.SafeError) as caught:
                record.Rpc(self.home)('GetRecordStatus')
        self.assertEqual(str(caught.exception), 'rpc_timeout')


    def test_doctorは画面ロック状態を報告する(self):
        for locked in (True, False, None):
            with self.subTest(locked=locked):
                self.assertIs(record.doctor(self.home, lock_state=lambda: locked).get('screen_locked'), locked)


class ScreenLockTests(unittest.TestCase):
    def test_本人の一意なコンソールで省略されたロックフラグは解除済みとする(self):
        user = {'kCGSSessionUserIDKey': 501, 'kCGSSessionOnConsoleKey': True}
        other = {'kCGSSessionUserIDKey': 502, 'kCGSSessionOnConsoleKey': True,
                 'CGSSessionScreenIsLocked': True}
        data = {'IOConsoleUsers': [other, user]}
        def runner(command, **kwargs):
            return subprocess.CompletedProcess(command, 0, plistlib.dumps(data), b'')
        with patch.object(os, 'getuid', return_value=501):
            self.assertIs(record.screen_locked(runner=runner), False)

    def test_省略フラグでも本人のコンソールが特定できなければ不明とする(self):
        user = {'kCGSSessionUserIDKey': 501, 'kCGSSessionOnConsoleKey': True}
        fixtures = [[dict(user, kCGSSessionUserIDKey=502)],
                    [dict(user, kCGSSessionOnConsoleKey=False)],
                    [user, dict(user)],
                    [user, dict(user, CGSSessionScreenIsLocked=True)]]
        for users in fixtures:
            def runner(command, **kwargs):
                return subprocess.CompletedProcess(command, 0, plistlib.dumps({'IOConsoleUsers': users}), b'')
            with self.subTest(users=users), patch.object(os, 'getuid', return_value=501):
                self.assertIsNone(record.screen_locked(runner=runner))

    def test_辞書と配列のplistから本人のコンソール状態だけを取得する(self):
        for locked in (True, False):
            user = {'kCGSSessionUserIDKey': 501, 'kCGSSessionOnConsoleKey': True,
                    'CGSSessionScreenIsLocked': locked, 'UserName': 'private-fixture-name'}
            other = {'kCGSSessionUserIDKey': 502, 'kCGSSessionOnConsoleKey': True,
                     'CGSSessionScreenIsLocked': not locked}
            for data in ({'IOConsoleUsers': [other, user]}, [{'children': [{'IOConsoleUsers': [user, other]}]}]):
                with self.subTest(locked=locked, shape=type(data).__name__), patch.object(os, 'getuid', return_value=501):
                    def runner(command, **kwargs):
                        self.assertEqual(command, ['/usr/sbin/ioreg', '-n', 'Root', '-d', '1', '-a'])
                        self.assertFalse(kwargs.get('shell', False))
                        self.assertLessEqual(kwargs['timeout'], 15)
                        return subprocess.CompletedProcess(command, 0, plistlib.dumps(data), b'')
                    self.assertIs(record.screen_locked(runner=runner), locked)

    def test_不明なフラグや他人のセッションを解除済みと推定しない(self):
        fixtures = [[], {}, {'IOConsoleUsers': []},
                    {'IOConsoleUsers': [{'kCGSSessionUserIDKey': 502, 'kCGSSessionOnConsoleKey': True, 'CGSSessionScreenIsLocked': False}]},
                    {'IOConsoleUsers': [{'kCGSSessionUserIDKey': 501, 'kCGSSessionOnConsoleKey': False, 'CGSSessionScreenIsLocked': False}]},
                    {'IOConsoleUsers': [{'kCGSSessionUserIDKey': 501, 'kCGSSessionOnConsoleKey': True, 'CGSSessionScreenIsLocked': 'false'}]}]
        for data in fixtures:
            with self.subTest(data=data), patch.object(os, 'getuid', return_value=501):
                def runner(command, **kwargs):
                    return subprocess.CompletedProcess(command, 0, plistlib.dumps(data), b'')
                self.assertIsNone(record.screen_locked(runner=runner))

    def test_失敗や壊れたplistのメタデータを漏らさない(self):
        for outcome in (subprocess.CompletedProcess([], 1, b'private-fixture-secret', b'private-fixture-name'),
                        subprocess.CompletedProcess([], 0, b'private-fixture-secret', b''),
                        subprocess.CompletedProcess([], 0, b'<?xml version="1.0"?><plist><private-fixture-secret>', b''),
                        subprocess.TimeoutExpired(['private-fixture-secret'], 5)):
            with self.subTest(kind=type(outcome).__name__):
                def runner(command, **kwargs):
                    if isinstance(outcome, Exception):
                        raise outcome
                    return outcome
                output = io.StringIO()
                with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                    self.assertIsNone(record.screen_locked(runner=runner))
                self.assertEqual(output.getvalue(), '')



if __name__ == '__main__':
    unittest.main()
