class ApplicationController < ActionController::Base
  include Clearance::Controller
  include ActionController::Live
  protect_from_forgery with: :exception
  before_action :require_login

  def reactor
    @reactor ||= Reactor.new(access_token)
  end

  def access_token
    @access_token ||= AdobeIo::AccessToken.new.generate
  end

  def sse
    @sse ||= SSE.new(response.stream)
  end

  def companies_for_select
    [[]] + reactor.companies.map do |data|
      [data.name, data.id]
    end
  end

  def render_text(title, results, alpha_url=nil)
    payload = results[:response].nil? ? '' : JSON.pretty_generate(results[:response])
    code = Pygments.highlight(payload ,:lexer => 'ruby')
    data = { title: title, alpha_url: alpha_url, code: code, url: results[:url] }
    # provision.events << Event.new(data: data)
    t = render_to_string(partial: 'shared/event', formats: [:html], locals: data)
    sse.write(t)
  end

  def alpha_host
    ENV['REACTOR_UI_HOST'] || 'https://lens-alpha.mcdp.adobemc.com'
  end

  def company_url
    "#{alpha_host}/company/#{company_id}"
  end

  def property_url
    "#{company_url}/property/#{property.id}" if property.present?
  end

  def property
    @property
  end
end
