from spm.backend.models import Content

# User login and stuff

# Updates and their comments

def post_update(author, content):
  update = Content(title=content["title"], content=content["content"], author=author)
  update.save(bucket="spm_posts")
  return update

def edit_update(key, content):
  update = Content.get(key, bucket="spm_posts")
  update.title = content["title"]
  update.content = content["content"]
  update.save(bucket="spm_posts")
  return update

def del_update(key):
  update = Content.get(key, bucket="spm_posts")
  for comment in update.comments:
    comment.delete()

  update.delete()

def add_comment(key, author, content):
  comment = Content(title=content["title"], content=content["content"], author=author)
  update = Content.get(key, bucket="spm_posts")
  update.comments.append(comment)
  comment.save(bucket="spm_comments")
  update.save(bucket="spm_posts")
  return comment

def edit_comment(key, content):
  comment = Content.get(key, bucket="spm_comments")
  comment.title = content["title"]
  comment.content = content["content"]
  comment.save(bucket="spm_comments")
  return comment

def del_comment(key, content):
  comment = Content.get(key, bucket="spm_comments")
  comment.delete()

