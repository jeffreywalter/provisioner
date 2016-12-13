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
    doc.data.map do |data|
      [data.name, data.id]
    end
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

  def create_aa_config(aa_ext_id, aa)
    ep_id = extension_packages.find
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
    js_id = delegate_id_for('javascript-variable', :data_elements, dtm)
    attributes = {
      "settings": "{\"path\":\"cart.amount\"}",
      "force_lowercase": false,
      "name": "shopping_cart",
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

  def create_click_rule_component(rule_id, dtm_ext)
    attributes = {
      "extension_id": dtm_ext.id,
      "settings": "{\"elementSelector\":\"a#checkout\",\"bubbleFireIfParent\":true,\"bubbleFireIfChildFired\":true}",
      "order": 0,
      "delegate_descriptor_id": delegate_id_for('click', :events, dtm_ext),
      "version": false
    }
    url = "#{reactor_host}/rules/#{rule_id}/rule_components"
    post_payload url, attributes, 'rule_components'
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

  private

  def delegate_id_for(name, type, extension)
    delegate_id = extension.send(type).find do |dtype|
      dtype['name'] == name
    end['id']
  end

  def post_payload(url, attributes, type)
    payload = {
      "data": {
        "attributes": attributes,
        "type": type
      }
    }
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
