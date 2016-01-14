import vim
import json
import urllib.request
from urllib.error import URLError

def downloadAndParseJSON():
    try:
        data = urllib.request.urlopen(vim.eval('l:requesturl')).read().decode('utf-8')
    except URLError:
        vim.command('let l:downloadfailed = "%s"' % 'Could not connect to URL')
        return

    try:
        parsedJSON = json.loads(data)
    except ValueError:
        vim.command('let l:downloadfailed = "%s"' % 'The server returned non-JSON')
        return

    datalocation = vim.eval('a:result')

    for part in datalocation.split('/'):
        try:
            part = int(part)
        except ValueError:
            pass

        try:
            parsedJSON = parsedJSON[part]
        except IndexError:
            vim.command('let l:downloadfailed = "%s"' % 'The requested data was not found on the expected position')
            break

    try:
        parsedJSON = parsedJSON.replace('"', '\\"')
    except AttributeError:
        vim.command('let l:downloadfailed = "%s"' % 'The requested data was not found on the expected position')

    vim.command('let l:parsedresult = "%s"' % parsedJSON)

downloadAndParseJSON()
