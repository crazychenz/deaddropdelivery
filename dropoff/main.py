from flask import Flask, request
from markupsafe import escape
from datetime import datetime
from cryptography.hazmat.primitives import serialization
import json
import hashlib
import jwt
import glob
import json

#privkey_fpath = 'id_rsa'
#pubkey_fpath = 'id_rsa.pub'

#privkey = open(privkey_fpath, 'r').read()
#pubkey = open(pubkey_fpath, 'r').read()

with open('config.json', 'rb') as fobj:
  cfg = json.loads(fobj.read())

app = Flask(__name__)

reqdb = {}


"""
The dropoff handler is responsible for accepting the request and sending it
into the request folder.
"""
# curl -v -X POST -H 'Content-Type: application/json' -d '{"repository":{"full_name":"crazychenz/vinnie.work"},"pusher":{}}' http://192.168.50.6/github-dropoff/
@app.route("/github-dropoff/%s" % cfg['dropoffkey'], methods = ['POST'])
def github_dropoff():
    if not request.is_json:
        return ''
    req = request.json
    # Source IP address lock with: request.headers.get('X-Real-Ip')
    #timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    if 'repository' not in req or not 'head_commit' in req:
        return 'Invalid'
    
    repo = req['repository']
    commit = req['head_commit']
    if 'full_name' not in repo and 'pushed_at' not in repo:
        return 'Invalid'
    if 'id' not in commit:
        return 'Invalid'
    
    # Assuming request is good here.
    # TODO: Verify safety of commitid and pushedat values.
    repo_hash = hashlib.sha1(repo['full_name'].encode('utf-8')).hexdigest()
    pushed_at = repo['pushed_at']
    commit_id = commit['id']

    fname = "requests/%s-%d-%s" % (repo_hash, pushed_at, commit_id)
    with open(fname, "wb") as fobj:
        fobj.write(json.dumps({'commit':commit_id}).encode('utf-8'))

    return fname


"""
The pickup handler is responsible for finding the newest file greater than
the provided time (in seconds).
"""
@app.route("/github-pickup/%s/<repo>/<pushed_after>" % cfg['pickupkey'], methods = ['GET'])
def github_pickup(repo, pushed_after):
    requests = glob.glob('requests/%s-*' % repo)
    requests.sort(key = lambda x: x.split('-')[1], reverse=True)
    if len(requests) < 1:
        return ''
    if int(requests[0].split('-')[1]) <= int(pushed_after):
        return ''

    return requests[0]


# start the development server using the run() method
if __name__ == "__main__":
    app.run(host="127.0.0.1", debug=True, port=8000)
