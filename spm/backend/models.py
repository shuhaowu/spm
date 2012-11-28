from riakkit import Document, StringProperty, DictProperty, BaseProperty, \
    MultiReferenceProperty, ReferenceProperty, DateTimeProperty, ListProperty, \
    BooleanProperty
import riak

import markdown
from lxml.html.clean import Cleaner

_cleaner = Cleaner(add_nofollow=True, style=True)
_markdown = markdown.Markdown(safe_mode="escape")

class MarkdownProperty(BaseProperty):
  class MD(DictProperty.DotDict):
    def get(self, markdown):
      return self.markdown if markdown else self.html

  @staticmethod
  def mdconverter(text):
    """Converts some text to a DotDict object with markdown and html as
attribute. Note that the argument text is unstripped. All security
have to go through this converter.

Args:
text: The input text probably directly submitted by the client.

Returns:
A DocDict object with an html field.
"""
    if isinstance(text, DictProperty.DotDict):
      return text
    elif isinstance(text, dict):
      return MarkdownProperty.MD(text)

    md = text
    # TODO: https://github.com/waylan/Python-Markdown/issues/101#issuecomment-5882555
    html = _markdown.convert(md)
    if len(html) > 0:
      html = _cleaner.clean_html(html)

    # TODO: Process Youtube Link

    return MarkdownProperty.MD({"markdown" : md, "html" : html})

  def __init__(self, mdconverter=None, **kwargs):
    BaseProperty.__init__(self, **kwargs)
    if mdconverter is not None:
      self.mdconverter = mdconverter

  def standardize(self, value):
    value = BaseProperty.standardize(self, value)
    return self.mdconverter(value)

  def convertFromDb(self, value):
    value = BaseProperty.convertFromDb(self, value)
    if value is None:
      return MarkdownProperty.MD({"markdown" : "", "html" : ""})
    return MarkdownProperty.MD(value)

  def defaultValue(self):
    return MarkdownProperty.MD({"markdown" : "", "html" : ""})

# models

class CustomDocument(Document):
  client = riak.RiakClient(port=8087, transport_class=riak.RiakPbcTransport)

class User(CustomDocument):
  bucket_name = "spm_user"

  # email in 2i
  name = StringProperty()
  positions = DictProperty() # project key -> position name


class Content(CustomDocument):
  bucket_name = ["spm_wallposts", "spm_comments"]

  title = StringProperty()
  content = MarkdownProperty()
  children = MultiReferenceProperty("self")
  author = ReferenceProperty(User)
  date = DateTimeProperty()

  # project in 2i

class TodoItem(CustomDocument):
  bucket_name ="spm_todo_items"

  title = StringProperty()
  desc = MarkdownProperty()
  pubdate = DateTimeProperty()
  duedate = DateTimeProperty(default=lambda: None)
  done = BooleanProperty(default=False)
  comments = MultiReferenceProperty(Content)
  author = ReferenceProperty(User)

  # 2i for assigned_to_bin
  # 2i for category_bin
  # 2i for project_bin

class Schedule(CustomDocument):
  bucket_name = "spm_schedule_items"

  title = StringProperty()
  desc = MarkdownProperty()
  location = StringProperty()
  starttime = DateTimeProperty()
  endtime = DateTimeProperty()

  # 2i for project_bin

class Project(CustomDocument):
  bucket_name = "spm_projects"

  name = StringProperty()
  desc = StringProperty()

  # 2i for "owners_bin" -> userkey
  # 2i for "participants_bin" -> userkey
  # 2i for "unregistered_bin" -> "<email> <type:owners/participants>"

class Files(CustomDocument):
  bucket_name = "spm_attachment"

  title = StringProperty(required=True)
  description = StringProperty(required=True)
  comments = MultiReferenceProperty(Content)
  author = ReferenceProperty(User)
  location = StringProperty(required=True)

  # project in 2i