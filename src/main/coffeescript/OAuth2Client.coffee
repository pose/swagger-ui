class OAuth2Client
  
  class Token
    constructor: (@accessToken, @tokenType, @expiresIn, @state) ->

  class Error
    constructor: (@message, @description) ->
      
  token: null
  timeout: null
  scopes: []
  authorizationEndpoint: null

  constructor: (@options={}) ->
    defaultOptions = {}
 
    ((@options[key] = value) for key, value of defaultOptions when @options[key] is undefined)

    mandatoryKeys = ['onComplete', 'onFailure', 'onUnauthorized', 'clientId']

    for key in mandatoryKeys
      if @options[key] is undefined
        throw new Error("#{key} parameter of oauth2 must be specified")

    result = @parseHashQueryString window.location.hash
    if result[0].accessToken? or result[1].message?
      localStorage['returnValue'] = JSON.stringify(result)
      window.close()

  unauthorize:() ->
    @options.onUnauthorized()

  register: (scopes, authorizationEndpoint) ->
    @scopes = scopes
    @authorizationEndpoint = authorizationEndpoint

    
  login: () ->
    query_params =
      response_type: 'token'
      client_id: @options.clientId
      redirect_uri: escape(window.location)
      # Fix workaround for Security Module
      scope: @scopes.join(' ')
    
    query_string = ("#{key}=#{value}" for key, value of query_params).join('&')

    authUrl = "#{@authorizationEndpoint}?#{query_string}"
    
    @popupWindow(authUrl, 'Authorize', 1024, 800)
    retVal = localStorage['returnValue']
    if retVal?
      [popUpToken, error] = JSON.parse(retVal)
      delete localStorage['returnValue']

    if error.message?
      @options.onFailure?(error)
    else if popUpToken.accessToken?
      @token = popUpToken
      @timeout = setTimeout(=>
        @options.onTokenExpired?(popUpToken)
        @logout()
      ,
      @token.expiresIn * 1000)
      @options.onComplete?(popUpToken)

  logout: () ->
    @token = null
    clearTimeout @timeout

  parseHashQueryString: (hash) ->
    # Removing initial hash (#)
    hash = hash.slice(1)
    entries = (entry.split('=') for entry in hash.split('&'))
    dic = {}
    for tuple in entries
      if tuple[0]? and tuple[0] isnt ''
        dic[tuple[0]] = tuple[1] ? true

    [new Token(dic['access_token'], dic['token_type'], dic['expires_in'], dic['state']),
      new Error(dic['error'], dic['error_description'])]

  popupWindow: (url, title, w, h) ->
    left = (screen.width/2)-(w/2)
    top = (screen.height/2)-(h/2)
    properties =
      toolbar: false
      location: false
      directories: false
      status: false
      menubar: false
      scrollbar: false
      resizable: false
      copyhistory: false
      dialogwidth: w
      dialogheight: h
      dialogtop: top
      dialogleft: left
      center: true
      scroll: false

    toText = (value) -> if value is false then "no" else value
    options = ("#{key}:#{toText(value)}" for key, value of properties).join('; ')
    
    showModalDialog(url,null,options)

window.OAuth2Client = OAuth2Client
