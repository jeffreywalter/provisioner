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
    doc.data
  end

  def create_property(company_id, property_name)
    url = "#{reactor_host}/companies/#{company_id}/properties"
    post_payload url, { "name": property_name }, 'properties'
  end

  def create_environment(property_id, environment_name)
    attributes = {
      "name": environment_name,
      "adapter": "akamai"
    }
    url = "#{reactor_host}/properties/#{property_id}/environments"
    post_payload url, attributes, 'environments'
  end

  def create_extension(property_id, extension_package_id)
    url = "#{reactor_host}/properties/#{property_id}/extensions"
    post_payload url, { "extension_package_id": extension_package_id }, 'extensions'
  end

  def create_aa_extension(property_id, extension_package_id)
    url = "#{reactor_host}/properties/#{property_id}/extensions"
    attributes = {
      "extension_package_id": extension_package_id,
      "settings": "{\"libraryCode\":{\"type\":\"managed\",\"accounts\":{\"production\":[\"dev\"],\"staging\":[\"dev\"],\"development\":[\"dev\"]},\"loadPhase\":\"pageBottom\"},\"trackerProperties\":{\"eVars\":[{\"type\":\"value\",\"name\":\"eVar4\",\"value\":\"%shopping_cart%\"}],\"trackInlineStats\":true,\"trackDownloadLinks\":true,\"trackExternalLinks\":true,\"linkDownloadFileTypes\":[\"doc\",\"docx\",\"eps\",\"jpg\",\"png\",\"svg\",\"xls\",\"ppt\",\"pptx\",\"pdf\",\"xlsx\",\"tab\",\"csv\",\"zip\",\"txt\",\"vsd\",\"vxd\",\"xml\",\"js\",\"css\",\"rar\",\"exe\",\"wma\",\"mov\",\"avi\",\"wmv\",\"mp3\",\"wav\",\"m4v\"]}}",
      "delegate_descriptor_id": "#{extension_package_id}::extensionConfiguration::config"
    }
    post_payload url, attributes, 'extensions'
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

  def create_data_element(property_id, name, dtm)
    js_id = delegate_id_for('javascript-variable', :data_elements, dtm.extension_package)
    path = FFaker::BaconIpsum.words.map{|w|w.parameterize.underscore}.join('.')
    attributes = {
      "settings": "{\"path\":\"#{path}\"}",
      "force_lowercase": false,
      "name": name,
      "order": 0,
      "storage_duration": "visitor",
      "delegate_descriptor_id": js_id,
      "default_value": "0",
      "clean_text": false,
      "extension_id": dtm.id,
      "version": false
    }
    url = "#{reactor_host}/properties/#{property_id}/data_elements"
    post_payload url, attributes, 'data_elements'
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
    "{\"browsers\":[\"OmniWeb\"]}"
  end

  def set_variables_settings
    "{\"trackerProperties\":{\"eVars\":[{\"type\":\"value\",\"name\":\"eVar2\",\"value\":\"%cost_per_click%\"},{\"type\":\"value\",\"name\":\"eVar3\",\"value\":\"%conversion%\"}],\"props\":[{\"type\":\"value\",\"value\":\"%click_through_rate%\",\"name\":\"prop2\"}]}}"
  end

  def create_rule_component(rule_id, ext, name, type)
    attributes = {
      "extension_id": ext.id,
      "settings": send("#{name.underscore}_settings"),
      "order": 0,
      "logic_type": 'and',
      "delegate_descriptor_id": delegate_id_for(name, type, ext.extension_package),
      "version": false
    }
    url = "#{reactor_host}/rules/#{rule_id}/rule_components"
    post_payload url, attributes, 'rule_components'
  end

  def create_library(property_id, name, environment_id, ids)
    attributes = {
      "name": name
    }
    res_data = ids.map do |res|
      {
        "id": res.first,
        "type": res.last
      }
    end

    relationships = {
      "environment": {
        "data": {
          "id": environment_id,
          "type": "environment"
        }
      },
      "resources": {
        "data": res_data
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
      package.name == name
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
    BaseHTTP.post(url, payload, headers)
  end

  def get_url(url)
    BaseHTTP.get(url+"?page%5Bsize%5D\=500", headers)
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
