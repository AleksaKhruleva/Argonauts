import os

print('ARGO_BASE="' + os.getenv('ARGO_BASE') + '"')
print('ARGO_USER="' + os.getenv('ARGO_USER') + '"')
print('ARGO_PASS="' + os.getenv('ARGO_PASS') + '"')

print(os.environ)