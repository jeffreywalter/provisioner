class Reactor
  attr_reader :access_token, :reactor_host
  def initialize(access_token)
    @access_token = access_token
    @reactor_host = ENV['REACTOR_HOST']
  end

  def companies
    url = "#{reactor_host}/companies"
    response = get_url(url)
    doc = JSON::Api::Vanilla.parse(response.to_json)
    companies = doc.data
    pagination = response['meta']['pagination']
    next_page = pagination['next_page']
    while !next_page.nil? && pagination['current_page'] < 2
      new_url = url + "?page%5Bnumber%5D=#{next_page}&page%5bsize%5D=100"
      new_response = get_url(new_url)
      new_doc = JSON::Api::Vanilla.parse(new_response.to_json)
      companies.concat new_doc.data
      pagination = new_response['meta']['pagination']
      next_page = pagination['next_page']
    end
    companies
  end

  def properties(company_id)
    url = "#{reactor_host}/companies/#{company_id}/properties"
    response = get_url(url)
    doc = JSON::Api::Vanilla.parse(response.to_json)
    properties = doc.data
    pagination = response['meta']['pagination']
    next_page = pagination['next_page']
    while !next_page.nil?
      new_url = url + "?page%5Bnumber%5D=#{next_page}&page%5bsize%5D=100"
      new_response = get_url(new_url)
      new_doc = JSON::Api::Vanilla.parse(new_response.to_json)
      properties.concat new_doc.data
      pagination = new_response['meta']['pagination']
      next_page = pagination['next_page']
    end
    properties
  end

  def property(property_id)
    url = "#{reactor_host}/properties/#{property_id}"
    get_url(url)
  end

  def extensions(property_id)
    url = "#{reactor_host}/properties/#{property_id}/extensions"
    get_url(url)
  end

  def scrub_payload(payload, remove_attrs=[])
    if payload.instance_of? Array
      payload.each do |h|
        scrub_attributes(payload, remove_attrs)
      end
    else
      scrub_attributes(payload, remove_attrs)
    end
  end

  def scrub_attributes(h, remove_attrs=[])
    delete_attrs = %w(created_at updated_at dirty disply_name published published_at revision review_status)
    ( delete_attrs + remove_attrs).each do |f|
      h.delete(f)
    end
    h
  end

  def create_company(name)
    org_id = SecureRandom.uuid.gsub('-','').upcase[0..-9] + "@AdobeOrg"
    attributes = {
      "org_id": org_id,
      "name": name
    }
    url = "#{reactor_host}/companies"
    post_payload url, attributes, 'companies'
  end

  def create_user(adobe_id, company_id, system_admin=false)
    relationships = {
      "companies": {
        "data": [{
          "id": company_id,
          "type": "companies"
        }]
      }
    }
    url = "#{reactor_host}/users"

    attributes = {
      "adobe_id": adobe_id,
      "system_admin": system_admin
    }

    post_payload url, attributes, 'users', relationships
  end

  def create_property(company_id, property_name: nil, payload: nil)
    url = "#{reactor_host}/companies/#{company_id}/properties"
    payload = payload || { "name": property_name, "platform": "web", "domains": ["renchair.com"] }
    post_payload url, scrub_payload(payload, %w(enabled)), 'properties'
  end

  def create_host(property_id, host_name)
    attributes = {
      "name": host_name,
      "type_of": "akamai"
    }
    url = "#{reactor_host}/properties/#{property_id}/hosts"
    post_payload url, attributes, 'hosts'
  end

  def create_environment(property_id, host_id, environment_name)
    attributes = {
      "name": environment_name,
      "stage": "development",
      "archive": false,
      "path": ""
    }

    relationships = {
      "host": {
        "data": {
          "id": host_id,
          "type": "hosts"
        }
      }
    }
    url = "#{reactor_host}/properties/#{property_id}/environments"
    post_payload url, attributes, 'environments', relationships
  end

  def create_extension(property_id, payload, relationship)
    url = "#{reactor_host}/properties/#{property_id}/extensions"
    post_payload url, scrub_payload(payload), 'extensions', relationship
  end

  def create_aa_extension(property_id, extension_package_id)
    url = "#{reactor_host}/properties/#{property_id}/extensions"
    attributes = {
      "settings": "{\"libraryCode\":{\"type\":\"managed\",\"accounts\":{\"production\":[\"dev\"],\"staging\":[\"dev\"],\"development\":[\"dev\"]}},\"trackerProperties\":{\"eVars\":[{\"type\":\"value\",\"name\":\"eVar4\",\"value\":\"%shopping_cart%\"}],\"trackInlineStats\":true,\"trackDownloadLinks\":true,\"trackExternalLinks\":true,\"linkDownloadFileTypes\":[\"doc\",\"docx\",\"eps\",\"jpg\",\"png\",\"svg\",\"xls\",\"ppt\",\"pptx\",\"pdf\",\"xlsx\",\"tab\",\"csv\",\"zip\",\"txt\",\"vsd\",\"vxd\",\"xml\",\"js\",\"css\",\"rar\",\"exe\",\"wma\",\"mov\",\"avi\",\"wmv\",\"mp3\",\"wav\",\"m4v\"]}}",
      "delegate_descriptor_id": "adobe-analytics::extensionConfiguration::config"
    }
    relationship = {
      "extension_package": {
        "data": {
          "id": "#{extension_package_id}",
          "type": "extension_packages"
        }
      }
    }
    post_payload url, attributes, 'extensions', relationship
  end

  def create_aa_config(aa_ext_id, aa)
    attributes = {
      "extension_id": aa_ext_id,
      "settings": "{\"libraryCode\":{\"type\":\"managed\",\"accounts\":{\"production\":[\"dev\"],\"staging\":[\"dev\"],\"development\":[\"dev\"]},\"loadPhase\":\"pageBottom\"},\"trackerProperties\":{\"eVars\":[{\"type\":\"value\",\"name\":\"eVar4\",\"value\":\"%shopping_cart%\"}],\"trackInlineStats\":true,\"trackDownloadLinks\":true,\"trackExternalLinks\":true,\"linkDownloadFileTypes\":[\"doc\",\"docx\",\"eps\",\"jpg\",\"png\",\"svg\",\"xls\",\"ppt\",\"pptx\",\"pdf\",\"xlsx\",\"tab\",\"csv\",\"zip\",\"txt\",\"vsd\",\"vxd\",\"xml\",\"js\",\"css\",\"rar\",\"exe\",\"wma\",\"mov\",\"avi\",\"wmv\",\"mp3\",\"wav\",\"m4v\"]}}",
      "order": 0,
      "delegate_descriptor_id": "#{aa.id}::extensionConfiguration::config",
      "name": "My Awesome Analytics Account",
    }

    url = "#{reactor_host}/extensions/#{aa_ext_id}/extension_configurations"
    post_payload url, attributes, 'extension_configurations'
  end

  # def create_property(company_id, property_name: nil, payload: nil)
  #   url = "#{reactor_host}/companies/#{company_id}/properties"
  #   payload = payload || { "name": property_name, "domains": ["renchair.com"] }
  #   post_payload url, scrub_payload(payload, %w(enabled)), 'properties'
  # end

  def data_elements(property_id)
    url = "#{reactor_host}/properties/#{property_id}/data_elements"
    get_url(url)
  end

  def create_data_element(property_id, name=nil, dtm=nil, payload=nil)
    attrs = payload
    if attrs.nil?
      js_id = delegate_id_for('javascript-variable', :data_elements, dtm.extension_package)
      path = FFaker::BaconIpsum.words.map{|w|w.parameterize.underscore}.join('.')
      attrs = {
        "settings": "{\"path\":\"#{path}\"}",
        "force_lowercase": false,
        "name": name,
        "order": 0,
        "storage_duration": "visitor",
        "delegate_descriptor_id": js_id,
        "default_value": "0",
        "clean_text": false,
        "version": false
      }
    end
    relationship = {
      "extension": {
        "data": {
          "id": "#{dtm.id}",
          "type": "extensions"
        }
      }
    }
    url = "#{reactor_host}/properties/#{property_id}/data_elements"
    post_payload url, scrub_payload(attrs), 'data_elements', relationship
  end

  def data_elements(property_id)
    url = "#{reactor_host}/properties/#{property_id}/data_elements"
    get_url(url)
  end

  def rules(property_id)
    url = "#{reactor_host}/properties/#{property_id}/rules"
    get_url(url)
  end

  def create_rule(property_id, name)
    attributes = {
      "name": name
    }
    url = "#{reactor_host}/properties/#{property_id}/rules"
    post_payload url, attributes, 'rules'
  end

  def click_settings
    "{\"elementSelector\":\"a#checkout\",\"bubbleFireIfParent\":true,\"bubbleFireIfChildFired\":true}"
  end

  def browser_settings
    "{\"browsers\":[\"Chrome\"]}"
  end

  def set_variables_settings
    "{\"trackerProperties\":{\"eVars\":[{\"type\":\"value\",\"name\":\"eVar2\",\"value\":\"%cost_per_click%\"},{\"type\":\"value\",\"name\":\"eVar3\",\"value\":\"%conversion%\"}],\"props\":[{\"type\":\"value\",\"value\":\"%click_through_rate%\",\"name\":\"prop2\"}]}}"
  end

  def rule_components(rule_id)
    url = "#{reactor_host}/rules/#{rule_id}/rule_components"
    get_url(url)
  end

  def create_rule_component(rule_json, ext=nil, name=nil, type=nil, payload=nil)
    attributes = payload
    property_id = rule_json.dig(*%w(data relationships property data id))
    rule_id = rule_json.dig(*%w(data id))
    if attributes.nil?
      attributes = {
        "extension_id": ext.id,
        "name": FFaker::Company.bs.titleize,
        "settings": send("#{name.underscore}_settings"),
        "order": 0,
        "logic_type": 'and',
        "delegate_descriptor_id": delegate_id_for(name, type, ext.extension_package),
        "version": false
      }
    end
    relationships = {
      "extension": {
        "data": {
          "id": "#{ext.id}",
          "type": "extensions"
        }
      },
      "rules": {
        "data": [
          {
            "id": rule_id,
            "type": "rules"
          }
        ]
      }
    }
    url = "#{reactor_host}/properties/#{property_id}/rule_components"
    post_payload url, attributes, 'rule_components', relationships
  end

  def library_relationship_data(ids)
    ids.map do |res|
      {
        "id": res.first,
        "type": res.last,
        "meta": {
          "action": "revise"
        }
      }
    end

  end

  def create_library(property_id, name, environment_id, rule_ids, data_element_ids, extension_ids)
    attributes = {
      "name": name
    }
    relationships = {
      "environment": {
        "data": {
          "id": environment_id,
          "type": "environments"
        }
      },
      "rules": {
        "data": library_relationship_data(rule_ids)
      },
      "data_elements": {
        "data": library_relationship_data(data_element_ids)
      },
      "extensions": {
        "data": library_relationship_data(extension_ids)
      }
    }
    url = "#{reactor_host}/properties/#{property_id}/libraries"
    post_payload url, attributes, 'libraries', relationships
  end

  def create_build(library_id)
    url = "#{reactor_host}/libraries/#{library_id}/builds"
    post_payload url, {}, 'builds'
  end

  def extension_for(property_id, extension_package_id)
    url = "#{reactor_host}/properties/#{property_id}/extensions"
    response = get_url(url)
    extensions = JSON::Api::Vanilla.parse(response.to_json)
    extensions.data.first
  end

  def extension_package_for(name)
    extension_packages.find do |package|
      package.name == name && package.platform == 'web'
    end
  end

  def extension_packages
    return @extension_packages if @extension_packages
    url = "#{reactor_host}/extension_packages"
    response = get_url(url)
    doc = JSON::Api::Vanilla.parse(response.to_json)
    @extension_packages = doc.data
  end

  def get_extension(id)
    url = "#{reactor_host}/extensions/#{id}?include=extension_package"
    response = get_url(url)
    JSON::Api::Vanilla.parse(response.to_json)
  end

  private

  def delegate_id_for(name, type, extension)
    delegate_id = extension.send(type).find do |dtype|
      dtype['name'] == name
    end['id']
  end

  def post_payload(url, attributes, type, relationships=nil)
    payload = {
      "data": {
        "attributes": attributes,
        "type": type
      }
    }
    payload[:data].merge!("relationships": relationships) if relationships.present?
    response = post_url(url, payload)
    doc = JSON::Api::Vanilla.parse(response.to_json)
    { url: url, doc: doc.data, response: response }
  end

  def post_url(url, payload)
    Rails.logger.info("POST '#{url}' with payload: #{payload}")
    response = ReactorHTTP.post(url, payload, headers)
    Rails.logger.info("Response: '#{response}'")
    response
  end

  def get_url(url)
    Rails.logger.info("GET '#{url}'")
    response = BaseHTTP.get(url+"?page%5Bsize%5D\=500", headers)
    Rails.logger.info("Response: '#{response}'")
    response
  end

  def headers
    headers = {
      "Accept" => "application/vnd.api+json;revision=1",
      "Content-Type" => "application/vnd.api+json",
      "X-Api-Key" => "Activation-DTM",
      "Authorization" => "bearer #{access_token}"
    }
  end
end
