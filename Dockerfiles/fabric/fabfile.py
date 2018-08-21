from fabric.api import run, env, sudo, roles, execute
from os.path import exists
env.user = 'ubuntu'
if exists('/fabric/id_rsa'):
  env.key_filename = '/fabric/id_rsa'
if exists('/fabric/id_dsa'):
  env.key_filename = '/fabric/id_dsa'
env.sudo_prefix = 'sudo '
env.skip_bad_hosts = True
env.connection_attempts = 3
env.timeout = 20
ubuntu_pass = Path("/fabric/ubuntu.pass")
if ubuntu_pass.is_file():
  with open(ubuntu_pass, 'r') as myfile:
    ubuntu=myfile.read().replace('\n', '')
    env.password = ubuntu_pass
    env.sudo_password = ubuntu_pass

env.roledefs = {
  'test': ['testhost1','testhost2'],
}
def hostname():
  sudo('hostname')
