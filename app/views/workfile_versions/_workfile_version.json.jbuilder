
json.id workfile_version.id
json.version_num workfile_version.version_num
json.commit_message workfile_version.commit_message
json.partial! 'shared/user', user: workfile_version.owner, title: 'owner', options: options
json.partial! 'shared/user', user: workfile_version.modifier, title: 'modifier', options: options
json.created_at workfile_version.created_at
json.updated_at workfile_version.updated_at
json.content_url workfile_version.contents.url
json.partial_file workfile_version.partial_file?
json.icon_url workfile_version.contents.url(:icon) if workfile_version.image?
json.content options[:contents] ? workfile_version.get_content(max_presentable_content_size) : nil

