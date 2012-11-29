config = ChorusConfig.instance
enabled = (config['kaggle.enabled'] == true) if config['kaggle']
api_key = config['kaggle.api_key'] if config['kaggle']

Kaggle::API.setup(enabled, api_key)