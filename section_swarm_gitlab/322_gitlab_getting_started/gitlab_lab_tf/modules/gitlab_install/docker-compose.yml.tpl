version: '3.8'

services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    hostname: ${gitlab_hostname}
    restart: always
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url '${gitlab_external_url}'
        gitlab_rails['initial_root_password'] = '${gitlab_root_password}'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
        %{ if enable_https }
        # Configuration HTTPS avec Let's Encrypt
        letsencrypt['enable'] = true
        letsencrypt['contact_emails'] = ['${letsencrypt_email}']
        letsencrypt['auto_renew'] = true
        nginx['redirect_http_to_https'] = true
        %{ else }
        # Désactiver HTTPS pour un lab simple
        nginx['redirect_http_to_https'] = false
        nginx['listen_https'] = false
        letsencrypt['enable'] = false
        %{ endif }
        # Performance pour lab
        puma['worker_processes'] = 2
        sidekiq['max_concurrency'] = 10
        prometheus_monitoring['enable'] = false
    ports:
      - "80:80"
      - "443:443"
      - "2222:22"
    volumes:
      - gitlab_config:/etc/gitlab
      - gitlab_logs:/var/log/gitlab
      - gitlab_data:/var/opt/gitlab
    shm_size: '256m'

volumes:
  gitlab_config:
  gitlab_logs:
  gitlab_data:
