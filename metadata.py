import sys
import markdown

with open(sys.argv[1], 'r') as file:
    data = file.read()

md = markdown.Markdown(extensions=['full_yaml_metadata'])
md.convert(data)

with open(sys.argv[2], 'w') as abstract:
    if 'abstract' in md.Meta.keys():
        abstract.write(md.Meta['abstract'])

with open(sys.argv[3], 'w') as title:
    if 'title' in md.Meta.keys():
        title.write(md.Meta['title'])

with open(sys.argv[4], 'w') as author:
    if 'author' in md.Meta.keys():
        author.write(md.Meta['author'])


