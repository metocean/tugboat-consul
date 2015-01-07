consul = require 'redwire-consul'
tug = require 'tugboat'
os = require 'os'
http = require 'http'
parse_url = require('url').parse

host = os.hostname()
host = process.env.TUG_HOST if process.env.TUG_HOST?

consulhost = 'http://192.168.59.103:8500'

consulhost = "http://#{consulhost}" if consulhost.indexOf('http://') isnt 0

key = "tugboathosts/#{host}/"
path = "/v1/kv/#{key}"
url = "#{consulhost}#{path}?keys"

launch = ->
  new consul.Watch url, (groups) ->
    groups = groups
      .map (g) -> g.substr key.length
      .filter (g) ->
        return no if g.length is 0
        return no if g.indexOf('/') isnt -1
        yes
    console.log groups
    
  console.log "Tugboat Consul is running for host #{host}..."

error = (e) ->
  console.error e
  process.exit -1

http
  .get url, (res) ->
    return launch() if res.statusCode isnt 404
    
    params = parse_url consulhost
    params.path = path
    params.method = 'PUT'
    
    req = http
      .request params, (res) -> launch()
      .on 'error', error
    req.end()
    
  .on 'error', error