# -*- coding: utf-8 -*-
from spm import app
from settings import DEBUG, DEPLOY_PORT

if __name__ == "__main__":
  if DEBUG == True:
    app.run(debug=True, host="", port=4131)
  else:
    from gevent.wsgi import WSGIServer
    http_server = WSGIServer(("127.0.0.1", DEPLOY_PORT), app)
    http_server.serve_forever()