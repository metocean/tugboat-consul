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

hascontainers = (group) ->
  for _, service of group.services
    return yes if service.containers.length isnt 0
  no

needsupdate = (group) ->
  for _, service of group.services
    return yes if service.diff.stop.length isnt 0
    return yes if service.diff.rm.length isnt 0
    return yes if service.diff.start.length isnt 0
    return yes if service.diff.create isnt 0
  no

launch = ->
  console.log "Tugboat Consul is running for host #{host}..."
  new Watch url, (groups) ->
    groups = groups
      .map (g) -> g.substr key.length
      .filter (g) ->
        return no if g.length is 0
        return no if g.indexOf('/') isnt -1
        yes
    console.log "Update received from consul, groups enabled: #{groups.join ', '}."
    console.log 'Querying tugboat...'
    tugboat = new Tugboat.API()
    tugboat.init (errors) ->
      return temperrors errors if errors?
      tugboat.diff (err, results) ->
        tasks = []
        groupstoupdate = []
        groupstocull = []
        
        for g in groups
          if !results[g]?
            console.log "Group #{g} is (unknown) and has no containers... nothing to do"
            continue
          group = results[g]
          delete results[g]
          continue unless needsupdate group
          groupstoupdate.push group
        
        for groupname, group of results
          continue unless hascontainers group
          continue if group.name.indexOf('tugboat') is 0
          groupstocull.push group
        
        for group in groupstocull
          do (group) ->
            tasks.push (cb) ->
              console.log "Culling group #{group.name}..."
              tugboat.groupcull group, (errors, messages) ->
                for err in errors
                  if err.stack then console.error err.stack
                  else console.error err
                for message in messages
                  console.log message
                cb()
        
        for group in groupstoupdate
          do (group) ->
            tasks.push (cb) ->
              if !group.isknown
                console.log "Updating group #{group.name} (unknown)... will start anything stopped"
              else
                console.log "Updating group #{group.name}..."
              tugboat.groupup group, (errors, messages) ->
                for err in errors
                  if err.stack then console.error err.stack
                  else console.error err
                for message in messages
                  console.log message
                cb()
        
        tasks.push (cb) ->
          if groupstoupdate.length is 0 and groupstocull.length is 0
            console.log "Everything is up to date"
          else
            console.log "Tugboat changes complete"
        
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
