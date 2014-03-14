class Mailer < ActionMailer::Base
  helper do
    def build_backbone_url(path)
      urls = Rails.configuration.action_mailer.default_url_options
      "#{urls[:protocol]}://#{urls[:host]}:#{urls[:port]}/##{path}"
    end
  end

  def notify(user, event)
    @user = user
    @job = event.job
    @workspace = event.workspace
    @job_result = event.job_result
    @job_task_results = event.job_result.job_task_results

    attachments['logo'] = logo(License.instance)
    attachments[RunWorkFlowTaskResult.name] = File.read(Rails.root.join('public', 'images', 'workfiles', 'icon', 'afm.png'))
    attachments[ImportSourceDataTaskResult.name] = File.read(Rails.root.join('public', 'images', 'import_icon.png'))

    m = mail(:to => user.email, :subject => event.header)
    m.deliver
  end

  def chorus_expiring(user, license)
    @user = user
    @expiration_date = license[:expires]
    @branding = license.branding
    attachments['logo'] = logo(license)
    m = mail(:to => user.email, :subject => 'Your Chorus license is expiring.')
    m.deliver
  end

  private

  def logo(license)
    File.read(Rails.root.join('public', 'images', %(#{license.branding}-logo.png)))
  end
end
