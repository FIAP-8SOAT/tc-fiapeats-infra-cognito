# tc-fiapeats-infra-cognito

Este projeto provisiona AWS Cognito utilizando Terraform que será utilizado no projeto fiapeats da fase 5, com o objetivo de autenticação de usuários, gerenciamento de sessões, provedores sociais e controle de permissões.

---

📌 Visão Geral

Neste projeto, utilizamos:

* User Pool para autenticação de usuários (e-mail/senha ou login social)
* Identity Pool (opcional) para acesso federado e permissões via IAM
* Integração com [ex: frontend React, backend Node.js, etc.]

---

🔑 Fluxo de Autenticação

1. Cadastro de Usuário:

* Via SignUp com e-mail e senha
* Recebe código de confirmação por e-mail

2. Login:

* Envia credenciais e recebe JWT tokens

3. Renovação de Sessão:

* Usa refresh token para manter o login

4. Logout:

* Invalida tokens no cliente


