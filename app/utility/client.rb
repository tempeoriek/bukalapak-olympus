class Client
  attr_accessor :version, :platform

  APPLICATION_NAME_MAPPER = {
    'bukalapak android apps'      => 'android_app',
    'bukalapak android apps new'  => 'android_app',
    'bukalapak ios apps'          => 'ios_app',
    'bukalapak ios apps new'      => 'ios_app',
    'desktop_web'                 => 'desktop_web',
    'bukalapak seller center'     => 'desktop_web',
    'bukalapak web'               => 'desktop_web',
    'bukalapak web new'           => 'desktop_web',
    'bukalapak mobile web'        => 'mobile_web',
    'bukalapak mobile web new'    => 'mobile_web',
    'bukalapak mitra application' => 'mitra_android_app'
  }.freeze

  PLATFORM_HAS_VERSION = %w(android_app ios_app).freeze

  def initialize(application_name, version)
    @platform = get_platform(application_name)
    @version = version
  end

  def name
    return "#{@platform}/#{@version}" if has_version?
    @platform
  end

  private

  def get_platform(application_name)
    platform_name = APPLICATION_NAME_MAPPER[application_name&.downcase]
    return nil if platform_name.nil?
    platform_name
  end

  def get_version(version = nil)
    version.present? ? version : nil
  end

  def has_version?
    PLATFORM_HAS_VERSION.include?(@platform)
  end
end
