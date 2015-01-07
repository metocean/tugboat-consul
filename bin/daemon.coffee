Watch = require('redwire-consul').Watch
Tugboat = require 'tugboat'
os = require 'os'
http = require 'http'
parse_url = require('url').parse
require 'colors'

# Run things one after another - better for human reading
series = (tasks, callback) ->
  tasks = tasks.slice 0
  next = (cb) ->
    return cb() if tasks.length is 0
    task = tasks.shift()
    task -> next cb
  result = (cb) -> next cb
  result(callback) if callback?
  result

host = os.hostname()
host = process.env.TUGBOAT_HOST if process.env.TUGBOAT_HOST?

consulhost = 'http://127.0.0.1:8500'
consulhost = process.env.CONSUL_HOST if process.env.CONSUL_HOST?
consulhost = "http://#{consulhost}" if consulhost.indexOf('http://') isnt 0

key = "tugboat/#{host}/"
path = "/v1/kv/#{key}"
url = "#{consulhost}#{path}?keys"

temperrors = (errors) ->
  for e in errors
    console.error e

fatalerror = (e) ->
  console.error e
  process.exit -1

launch = ->
  console.log "Tugboat Consul is running for host #{host}..."
  new Watch url, (groups) ->
    groups = groups
      .map (g) -> g.substr key.length
      .filter (g) ->
        return no if g.length is 0
        return no if g.indexOf('/') isnt -1
        yes
    tugboat = new Tugboat.API()
    tugboat.init (errors) ->
      return temperrors errors if errors?
      tugboat.diff (err, results) ->
        tasks = []
        for g in groups
          do (g) ->
            tasks.push (cb) ->
              if !results[g]?
                console.log "#{g} is (unknown) and has no containers... nothing to do".magenta
              else
                group = results[g]
                if !group.isknown
                  console.log "tug up #{g} (unknown)..."
                else
                  console.log "tug up #{g}..."
                delete results[g]
                tugboat.groupup group, (errors, messages) ->
                  for err in errors
                    if err.stack then console.error err.stack
                    else console.error err
                  for message in messages
                    console.log message
                  cb()
        for groupname, group of results
          do (groupname, group) ->
            tasks.push (cb) ->
              console.log "tug rm #{groupname}"
              cb()
        series tasks, ->

# check if the folder exists, if not create it
http
  .get url, (res) ->
    return launch() if res.statusCode isnt 404
    params = parse_url consulhost
    params.path = path
    params.method = 'PUT'
    http
      .request params, (res) -> launch()
      .on 'error', fatalerror
      .end()
  .on 'error', fatalerror
