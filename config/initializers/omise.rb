Rails.configuration.omise = {
  :setPublicKey => 'pkey_test_53x6wu9xs4h7zqkzq37',
  :secret_key => 'skey_test_53x6wu9xtwffpegkhvk'
}
Omise.api_key = Rails.configuration.omise[:secret_key]
