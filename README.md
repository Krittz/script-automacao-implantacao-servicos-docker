# SCRIPT DE AUTOMAÇÃO UTILIZANDO SHELL SCRIPT PARA IMPLANTAÇÃO DE SERVIDORES EM AMBIENTES DE DESENVOLVIMENTO UTILIZANDO DOCKER 


## Descrição

Este script foi desenvolvido para facilitar a criação e gerenciamento de containers Docker em sistemas Linux, tendo disponíveis: servidores web; servidores SFTP; e bancos de dados.
A ideia deste projeto é automatizar tarefas rotineiras para desenvolvedores, facilitando e padronizando a configuração de ambientes de desenvovlimento, economizando tempo e trazendo facilidade
para usuários com menos conhecimento.
Neste Script você encontrará a instalação completo do Docker, e a criação de containers para serviços importantes no dia a dia, como:
- Bancos de dados;
- Servidores web para testar suas aplicações, proxy reverso;
- Servidores seguros de transferência de arquivos.


## Funcionalidades

- **Verificação de Instalação do Docker**: Certifica-se de que o Docker está instalado antes de continuar.
- **Criação de Containers para Servidores Web**: Cria e configura containers para aplicações, front-end e para proxy reverso, utilizando servidores Apache e NGINX.
- **Criação de Containers para Servidores SFTP**: Cria e configura containers para servidores de transferência segura de arquivos, tanto o VSFTPD e o OpenSSH.
- **Criação de Containers para Bancos de Dados**: Cria e configura containers para MySQL, PostgreSQL e MariaDB, deixando-os pronto para uso.
- **Backup de Bancos de Dados**: Realiza backups de bancos de dados MySQL, PostgreSQL e MariaDB.
- **Restauração de Bancos de Dados**: Restaura bancos de dados MySQL, PostgreSQL e MariaDB a partir de arquivos de backup, criando novos containers ou reaproveitando antigos.
- **Aplicação de limite de conexões a containers utilizando Firewall UFW.
- **Aplicação de bloqueio de IP's a containers utilziando Firewall UFW.

## Pré-requisitos

- Acesso à linha de comando.

## Uso

### 1. Clonar o Repositório

```bash
git clone https://github.com/Krittz/script-automacao-implantacao-servicos-docker.git
cd script-automacao-implantacao-servicos-docker/
```
ou
```bash
git clone git@github.com:Krittz/script-automacao-implantacao-servicos-docker.git
cd script-automacao-implantacao-servicos-docker/
```
### 2. Conceder permissão de execução

```bash
sudo chmod +x script.sh
```
### 3. Executar o script

```bash
sudo ./script.sh
```
