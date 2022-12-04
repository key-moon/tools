#!/usr/bin/python

import time
from argparse import ArgumentParser, REMAINDER
import os
from os import path
import shlex

parser = ArgumentParser(description="")

parser.add_argument("--dir", "-d", nargs='?', dest='ENVFILE_DIR', default=os.getenv('ENVFILE_DIR', None), help="ディレクトリ")
parser.add_argument("--file", "-F", nargs='?', dest='ENVFILE_NAME', default=os.getenv('ENVFILE_NAME', 'env.txt'), help="環境構成を保存するファイル名")
parser.add_argument("--sync", dest='SYNC', action='store_const', default=False, const=True, help="リモートと同期")
parser.add_argument("--revert", dest='REVERT', action='store_const', default=False, const=True, help="前回の履歴を削除")
parser.add_argument("--no-push", dest='SHOULD_COMMIT', action='store_const', default=True, const=False, help="プッシュを行わない")
parser.add_argument("--no-commit", dest='SHOULD_PUSH', action='store_const', default=True, const=False, help="コミットを行わない")
parser.add_argument("--verbose", "-v", dest='VERBOSE', action='store_const', default=False, const=True, help="詳細な出力")

parser.add_argument("CMD", nargs=REMAINDER, help="実行するコマンド")
res = parser.parse_args()

if res.ENVFILE_DIR is None:
  raise Exception("[!] must specify ENVFILE_DIR environment variable or --dir argument")
ENVFILE_DIR = path.abspath(res.ENVFILE_DIR)
if not path.exists(ENVFILE_DIR):
  raise Exception("[!] must specify exist path for ENVFILE_DIR")
ENVFILE_NAME = res.ENVFILE_NAME

VERBOSE = res.VERBOSE
REVERT = res.REVERT
SYNC = res.SYNC
SHOULD_EXEC = True

def info(msg):
  if not VERBOSE: return
  print(f'[*] {msg}')

def check_exec(cmds):
  cmd = shlex.join(cmds)
  info(f'execute command: {cmd}')
  status = os.system(cmd)
  if not status: return
  print(f"[!] error: {status}")
  exit(status)


def pull_if_needed():
  if not SYNC: return
  info(f'pull repostory')
  check_exec(['git', 'pull'])

def commit_envfile_if_needed(msg='update envfile'):
  if not res.SHOULD_COMMIT: return
  info(f'commit envfile')
  check_exec(['git', 'add', ENVFILE_NAME])
  check_exec(['git', 'commit', '--no-gpg-sign', '-m', msg])

def push_if_needed():
  if not res.SHOULD_PUSH: return
  info(f'push repostory')
  check_exec(['git', 'push'])

info(f'chdir to {ENVFILE_DIR}')
os.chdir(ENVFILE_DIR)
pull_if_needed()

if REVERT:
  info(f'open {ENVFILE_NAME}')
  with open(ENVFILE_NAME, 'rb') as f:
    content = f.read()
    ind = content.rindex(b'#=')
  with open(ENVFILE_NAME, 'wb') as f:
    f.write(content[:ind])
  commit_envfile_if_needed('revert')
  push_if_needed()
  exit(0)

if SHOULD_EXEC:
  CMD = shlex.join(res.CMD)
  if not res.CMD:
    raise Exception("[!] command is empty")
  info(f'open {ENVFILE_NAME}')
  with open(ENVFILE_NAME, 'a') as f:
    check_exec(res.CMD)
    info(f'write executed command: {CMD}')
    f.writelines([f'#= {int(time.time())}\n', CMD, '\n'])
  commit_envfile_if_needed()
  push_if_needed()
  exit(0)
