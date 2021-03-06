# -*- coding: utf-8 -*-
import os

def getBlueprints():
  blueprints = []
  views_dir = os.path.dirname(os.path.abspath(__file__))
  for fname in os.listdir(views_dir):
    if fname.startswith("v_") and fname.endswith(".py"):
      _temp = __import__("spm.blueprints.%s" % fname[:-3], globals(), locals(), ["blueprint", "meta"])
      blueprints.append((_temp.blueprint, _temp.meta))

  return blueprints

blueprints = getBlueprints()
