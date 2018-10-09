Ext = Struct.new(:id)
class DuplicateController < ApplicationController
  def new
    render :new, locals: { companies: companies_for_select}
  end

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    begin
      duplicate_property
    rescue IOError
      # Client Disconnected
    ensure
      sse.close
    end
  end

  def properties
    response.headers['Content-Type'] = 'text/event-stream'
    begin
      sse.write(company_properties(params[:company_id]))
    rescue IOError
      # Client Disconnected
    ensure
      sse.close
    end
  end

  def duplicate_property
    # TODO: set @company_id
    # TODO: set @source_property_id
    source_property = reactor.property(source_property_id)
    payload = source_property['data']['attributes'].tap do |h|
      h['name'] = target_property_name
    end
    @company_id = source_property['data']['links']['company'][/(?<=companies\/).*/]
    # @company_id = 'CO20beeeda3ecf49f49838a970681dbad2' # waltermotorsports
    @company_id = 'COfb1c920eeb554da9be4d063e12c2e950'

    results = reactor.create_property(company_id, payload: payload)
    @property = results[:doc]
    render_text("Created property '#{target_property_name}'", results, "#{property_url}/overview")

    return if results[:response]['errors'].present?
    results = reactor.extensions(source_property_id)
    core_ext_id = reactor.extensions(property.id, true)['data'].first['id']

    # source_extension_packages = reactor.extension_packages.map {|ep| [ep.name, ep.id] }
    target_extension_packages = reactor.extension_packages(true).select {|ep| ep.platform == 'web' }.map {|ep| [ep.name, ep.id] }

    extensions = results['data'].each_with_object({}) do |ext, memo|
      if ext['attributes']['name'] == 'core'
        memo[ext['id']] = core_ext_id
        next
      end

      payload = {
        "delegate_descriptor_id": ext['attributes']['delegate_descriptor_id'] || '',
        "settings": ext['attributes']['settings'] || ''
      }
      exp_id = ext['relationships']['extension_package']['data']['id']
      puts "Trying to install #{exp_id} for extension #{ext['id']}"
      source_ep = reactor.get_extension_package(exp_id)
      target_exp_id = target_extension_packages.find { |exp| exp.first == source_ep.data.name }.last

      ext['relationships']['extension_package']['data']['id'] = target_exp_id
      if target_exp_id == 'EP5f69cb6929074c798693649fbaec75bf'
        settings_h = JSON.parse(payload[:settings])
        settings_h['targetSettings']['supplementalDataIdParamTimeout'] = 30
        settings_h['targetSettings']['authoringScriptUrl'] = "//cdn.tt.omtrdc.net/cdn/target-vec.js"
        settings_h['targetSettings']['urlSizeLimit'] = 2048
        payload[:settings] = settings_h.to_json
      end

      if target_exp_id == 'EP92eafb51a6704e85b5f8d4a923635cdc'
        payload[:delegate_descriptor_id] = 'trustarc-notice::extensionConfiguration::config'
      end

      result = reactor.create_extension(property.id, payload, ext['relationships'])
      new_ext = result[:doc]
      eurl = "#{property_url}/extensions/#{new_ext&.id}"
      render_text("Added #{new_ext&.display_name} Extension", result, eurl)
      memo[ext['id']] = new_ext&.id
    end

    # get data elements, and post
    data_element_results = reactor.data_elements(source_property_id)
    data_element_results['data'].each do |de_result|
      payload = de_result['attributes']
      extension_id = extensions[de_result['relationships']['extension']['data']['id']]
      ext = Ext.new(extension_id)
      de_response = reactor.create_data_element(@property.id, nil, ext, payload)
      de = de_response[:doc]
      aurl = "#{property_url}/data_elements/#{de&.id}"
      render_text("Created Data Element '#{de&.name}'", de_response, aurl)
    end

    rules_results = reactor.rules(source_property_id)
    rules_results['data'].each do |rule_result|
      name = rule_result['attributes']['name']
      # next if name != "Analytics : Click Event : Email Subscription"
      rule_response = reactor.create_rule(property.id, name)

      rule = rule_response[:doc]
      aurl = "#{property_url}/rules/#{rule&.id}"
      render_text("Created Rule '#{rule&.name}'", rule_response, aurl)

      rc_results = reactor.rule_components(rule_result['id'])
      rc_results['data'].each do |rc_result|
        payload = rc_result['attributes']
        extension_id = extensions[rc_result['relationships']['extension']['data']['id']]
        ext = Ext.new(extension_id)
        rc_response = reactor.create_rule_component(rule.id, ext, nil, nil, payload)
        rc = rc_response[:doc]
        aurl = "#{property_url}/rule_components/#{rc&.id}"
        render_text("Created Rule Component '#{rc&.name}'", rc_response, aurl)
      end
    end

    # create a dev adapter
    results = reactor.create_adapter(property.id, "Managed by Adobe")
    adapter = results[:doc]
    aurl = "#{property_url}/adapters/#{adapter&.id}"
    render_text("Created Adapter 'Managed by Adobe'", results, aurl)

    # create a dev environment : save the embed code
    results = reactor.create_environment(property.id, adapter.id, "Development")
    environment = results[:doc]
    aurl = "#{property_url}/environments/#{environment&.id}"
    render_text("Created Development Environment 'Development'", results, aurl)

    results = { url: property_url }
    render_text("Duplication Complete! Go have fun!", results, "#{property_url}/overview")
  end

  def source_property_id
    @source_property_id ||= params[:source_property_id]
  end

  def target_property_name
    @target_property_name ||= params[:target_property_name]
  end

  def company_id
    @company_id
  end

  def company_properties(company_id)
    reactor.properties(company_id).map do |p|
      [p.name, p.id]
    end.to_json
  end
end
