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

    results = reactor.create_property(company_id, payload: payload)
    @property = results[:doc]
    render_text("Created property '#{target_property_name}'", results, "#{property_url}/overview")

    return if results[:response]['errors'].present?
    results = reactor.extensions(source_property_id)
    core_ext_id = reactor.extensions(property.id)['data'].first['id']
    extensions = results['data'].each_with_object({}) do |ext, memo|
      if ext['attributes']['name'] == 'core'
        memo[ext['id']] = core_ext_id
        next
      end

      payload = {
        "extension_package_id": ext['relationships']['extension_package']['links']['related'][/(?<=extension_packages\/).*/],
        "delegate_descriptor_id": ext['attributes']['delegate_descriptor_id'] || '',
        "settings": ext['attributes']['settings'] || ''
      }

      result = reactor.create_extension(property.id, payload)
      new_ext = result[:doc]
      eurl = "#{property_url}/extensions/#{new_ext&.id}"
      render_text("Added #{new_ext&.display_name} Extension", result, eurl)
      memo[ext['id']] = new_ext&.id
    end

    # get data elements, and post
    data_element_results = reactor.data_elements(source_property_id)
    data_element_results['data'].each do |de_result|
      payload = de_result['attributes'].tap do |h|
        h['extension_id'] = extensions[de_result['links']['extension'][/(?<=extensions\/).*/]]
      end
      de_response = reactor.create_data_element(@property.id, nil, nil, payload)
      de = de_response[:doc]
      aurl = "#{property_url}/dataElements/#{de&.id}"
      render_text("Created Data Element '#{de&.name}'", results, aurl)
    end

    # for each rule in source
    #   get rule components for rule
    #   create rule
    #   create rule_components if for good extension
    #   render "cannot create component" for bad extensions
    #
    # create a new adapter
    # create a new environment
    # create a library
    # add all resources to that library
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
