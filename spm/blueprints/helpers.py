# -*- coding: utf-8 -*-
from flask import abort, session
from functools import wraps

def login_required(f):
  @wraps(f)
  def df(*args, **kwargs):
    if session.get("key", False):
      return f(*args, **kwargs)
    else:
      return abort(403)

  return df