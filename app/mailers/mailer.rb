class Mailer < ActionMailer::Base
  helper do
    def build_backbone_url(path)
      url_options = Rails.configuration.action_mailer.default_url_options
      "http://#{url_options[:host]}:#{url_options[:port]}/##{path}"
    end
  end

  def notify(user, event)
    @user = user
    @job = event.job
    @workspace = event.workspace
    @job_result = event.job_result
    @job_task_results = event.job_result.job_task_results

    attachments['logo'] = File.read(Rails.root.join('public', 'images', ChorusConfig.instance.branding_logo))
    attachments[RunWorkFlowTaskResult.name] = File.read(Rails.root.join('public', 'images', 'workfiles', 'icon', 'afm.png'))
    attachments[ImportSourceDataTaskResult.name] = File.read(Rails.root.join('public', 'images', 'import_icon.png'))

    m = mail(:to => user.email, :subject => event.header)
    m.deliver
  end
end
