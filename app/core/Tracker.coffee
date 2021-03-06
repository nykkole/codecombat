{me} = require 'core/auth'

debugAnalytics = false

module.exports = class Tracker
  constructor: ->
    if window.tracker
      console.error 'Overwrote our Tracker!', window.tracker
    window.tracker = @
    @isProduction = document.location.href.search('codecombat.com') isnt -1
    @identify()

  identify: (traits) ->
    console.log 'Would identify', traits if debugAnalytics
    return unless me and @isProduction and analytics? and not me.isAdmin()
    # https://segment.io/docs/methods/identify
    traits ?= {}
    for userTrait in ['email', 'anonymous', 'dateCreated', 'name', 'wizardColor1', 'testGroupNumber', 'gender']
      traits[userTrait] ?= me.get(userTrait)
    analytics.identify me.id, traits

  trackPageView: (name=null, includeIntegrations=null) ->
    # Google Analytics does not support event-based funnels, so we have to use virtual pageviews instead
    # https://support.google.com/analytics/answer/1032720?hl=en
    # https://segment.com/docs/libraries/analytics.js/#page
    unless name?
      name = Backbone.history.getFragment()
    console.log "Would track analytics pageview: /#{name}" if debugAnalytics
    return unless @isProduction and analytics? and not me.isAdmin()
    if includeIntegrations
      options = integrations: {'All': false}
      for integration in includeIntegrations
        options.integrations[integration] = true
      analytics.page "/#{name}", {}, options
    else
      analytics.page "/#{name}"

  trackEvent: (action, properties, includeIntegrations=null) =>
    # 'action' is a string
    # Google Analytics properties format: {category: 'Account', label: 'Premium', value: 50 }
    # https://segment.com/docs/integrations/google-analytics/#track
    # https://developers.google.com/analytics/devguides/collection/gajs/eventTrackerGuide#Anatomy
    # Mixpanel properties format: whatever you want unlike GA
    # https://segment.com/docs/integrations/mixpanel/
    console.log 'Would track analytics event:', action, properties if debugAnalytics
    return unless me and @isProduction and analytics? and not me.isAdmin()
    properties = properties or {}
    context = {}
    if includeIntegrations
      # https://segment.com/docs/libraries/analytics.js/#selecting-integrations
      context.integrations = {'All': false}
      for integration in includeIntegrations
        context.integrations[integration] = true
    analytics?.track action, properties, context

  trackTiming: (duration, category, variable, label, samplePercentage=5) ->
    # https://developers.google.com/analytics/devguides/collection/gajs/gaTrackingTiming
    return console.warn "Duration #{duration} invalid for trackTiming call." unless duration >= 0 and duration < 60 * 60 * 1000
    console.log 'Would track timing event:', arguments if debugAnalytics
    window._gaq?.push ['_trackTiming', category, variable, duration, label, samplePercentage]
