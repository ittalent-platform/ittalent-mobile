"""Drive only the dedicated Documents Android integration test's system dialogs.
Usage: python tool/documents_native_dialogs.py --adb <adb.exe> --flutter <flutter.bat> --device emulator-5554 --evidence D:/wdp/mobile-documents-evidence
The emulator must already be booted. No backend is used.
"""
import argparse, hashlib, json, pathlib, re, subprocess, time, xml.etree.ElementTree as ET
p=argparse.ArgumentParser();p.add_argument('--adb',required=True);p.add_argument('--flutter',required=True);p.add_argument('--device',default='emulator-5554');p.add_argument('--evidence',required=True);p.add_argument('--attach',action='store_true');p.add_argument('--test',default='integration_test/documents_files_native_test.dart');p.add_argument('--timeout',type=int,default=2400);a=p.parse_args()
out=pathlib.Path(a.evidence).resolve();out.mkdir(parents=True,exist_ok=True)
def adb(*args,timeout=30):
 try:return subprocess.run([a.adb,'-s',a.device,*args],capture_output=True,timeout=timeout)
 except subprocess.TimeoutExpired:return subprocess.CompletedProcess(args,124,b'',b'ADB timed out')
if adb('get-state').returncode:raise SystemExit('BLOCKED: Android emulator unavailable')
logpath=out/'native-integration.log';log=None if a.attach else logpath.open('w',encoding='utf-8')
proc=None if a.attach else subprocess.Popen([a.flutter,'test',a.test,'-d',a.device],stdout=log,stderr=subprocess.STDOUT)
start=time.monotonic();handled=set();actions=[]
try:
 while (proc is None or proc.poll() is None) and time.monotonic()-start<a.timeout:
  time.sleep(1)
  text=logpath.read_text(encoding='utf-8',errors='replace')
  if a.attach and ('All tests passed!' in text or 'Some tests failed.' in text):break
  phases=re.findall(r'NATIVE_PHASE (\w+)',text)
  if not phases or phases[-1] in handled:continue
  phase=phases[-1]
  if adb('shell','uiautomator','dump','/sdcard/documents-native-window.xml').returncode:continue
  raw=adb('shell','cat','/sdcard/documents-native-window.xml').stdout
  try:root=ET.fromstring(raw)
  except ET.ParseError:continue
  nodes=list(root.iter('node'))
  if not any('documentsui' in n.get('package','') for n in nodes):continue
  target=None
  if phase in ('save','duplicate'):
   target=next((n for n in nodes if n.get('text','').lower() in ('save','lưu') and n.get('enabled')=='true'),None)
  elif phase=='pick':
   target=next((n for n in nodes if n.get('text')=='mobile_documents_native_probe_20261022.pdf'),None)
  elif phase.startswith('cancel'):
   adb('shell','input','keyevent','4');actions.append(phase);continue
  if target is None:continue
  screenshot=adb('exec-out','screencap','-p').stdout
  (out/f'native_{phase}_dialog.png').write_bytes(screenshot)
  x1,y1,x2,y2=map(int,re.findall(r'\d+',target.get('bounds','')))
  tapped=adb('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))
  if tapped.returncode==0:
   handled.add(phase);actions.append(phase)
 if proc is not None and proc.poll() is None:
  subprocess.run(['taskkill','/PID',str(proc.pid),'/T','/F'],capture_output=True);proc.wait(timeout=20)
finally:
 if log is not None:log.close()
exitcode=proc.returncode if proc is not None else (0 if 'All tests passed!' in logpath.read_text(encoding='utf-8',errors='replace') else 1)
result={'exitCode':exitcode,'dialogActions':actions,'files':[]}
listing=adb('shell','ls','/sdcard/Download').stdout.decode(errors='replace').splitlines()
for name in listing:
 if name.startswith('mobile_documents_native_probe_20261022') and name.endswith('.pdf'):
  local=out/name
  pulled=adb('pull','/sdcard/Download/'+name,str(local))
  if pulled.returncode==0:result['files'].append({'name':name,'bytes':local.stat().st_size,'sha256':hashlib.sha256(local.read_bytes()).hexdigest()})
expected=b'%PDF-1.4\n% Mobile Documents native fixture, no personal data\n%%EOF\n'
result['expectedSha256']=hashlib.sha256(expected).hexdigest()
result['allHashesMatch']=bool(result['files']) and all(f['sha256']==result['expectedSha256'] for f in result['files'])
(out/'native-result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=True,indent=2))
raise SystemExit(0 if exitcode==0 and result['allHashesMatch'] else 1)
