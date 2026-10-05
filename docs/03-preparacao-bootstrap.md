# Parte 2 — preparação e bootstrap

Free Trial ativa e spending limit On confirmados via ARM; disponibilidade de créditos conferida antes da implantação. Nenhuma alteração de modalidade/cobrança.

## Resultados
- Quatro recursos do bootstrap criados; nenhuma VM ou rede de workload.
- Bootstrap validado, aplicado e plano posterior sem mudanças.
- Backend remoto inicializado; marcador terraform_data gravado, lock adquirido/liberado e plano posterior sem mudanças.
- Blob de estado confirmado com 895 bytes e lease disponível após operação.
- Primeiro acesso recebeu AuthorizationPermissionMismatch durante propagação da role; nova tentativa funcionou sem abrir firewall/habilitar chave.
- Terraform 1.14.3, Azure CLI 2.80.0, Git 2.52.0, AzureRM 4.74.0 fixado e lock file gerado.
- Durante esta etapa, Storage e versões do estado permaneceram ativos e sujeitos a consumo. Foram removidos no encerramento; a estimativa abaixo não é consumo medido.

## O que cada bloco faz
- `bootstrap/versions.tf`: fixa AzureRM 4.74.0, usa sua sessão Azure CLI e mantém estado local do bootstrap.
- `bootstrap/main.tf`: RG, StorageV2 Standard LRS Hot, container privado e RBAC de dados no container para o executor.
- Firewall do Storage aceita somente IPv4 administrativo. HTTPS/TLS 1.2, autenticação Entra ID e acesso anônimo/chaves desabilitados.
- `foundation/versions.tf`: configura o backend remoto e um marcador Terraform. No repositório final, o mesmo root também contém rede e governança: um apply da foundation já cria esses recursos, mesmo com workload desabilitado.
- Estado do bootstrap fica local para conseguir remover o backend por último. Nunca publicar `.tfstate`, planos ou valores locais.

## Execução
Depois de validar Free Trial, spending limit e crédito disponível:

```powershell
terraform -chdir=bootstrap init
terraform -chdir=bootstrap fmt -check
terraform -chdir=bootstrap validate
terraform -chdir=bootstrap plan -out=bootstrap.tfplan
# Revisar quatro criações, sem VMs ou alteração de cobrança.
terraform -chdir=bootstrap apply bootstrap.tfplan
# Gerar configuração local e inicializar backend:
./scripts/Initialize-FoundationBackend.ps1
# O código final já inclui a Parte 3. Revise também rede e governança.
terraform -chdir=foundation plan -out=foundation.tfplan
terraform -chdir=foundation apply foundation.tfplan
terraform -chdir=foundation plan -detailed-exitcode
```

A sequência de planos acima usa o código final. O teste original com apenas um marcador de backend é uma evidência histórica, não um modo isolado disponível no root atual. Preencha os arquivos locais de variáveis dos dois roots antes de executar.

Se RBAC ainda estiver propagando, repetir somente init/consulta após aguardar; não abrir firewall nem habilitar chaves como solução.

## Remoção
Destruir foundation antes do bootstrap. O estado local em bootstrap deve ser preservado até a remoção do backend. O IP administrativo pode precisar de atualização se o provedor de Internet mudar o endereço. Não usar operações manuais de exclusão para contornar Terraform sem registrar recuperação de estado.

## Custo de referência do backend
Catálogo público BRL, Brazil South, General Block Blob v2 Hot LRS, consultado em 2026-09-21:
- Primeira faixa de armazenamento: R$ 0,1685/GB-mês.
- Escritas: R$ 0,3619/10 mil operações.
- Leituras: R$ 0,029/10 mil operações.
- Listagem/criação de containers: R$ 0,3619/10 mil operações.
- Outras operações: R$ 0,029/10 mil operações.

Hipótese conservadora de laboratório: 1 GB-mês (incluindo versões) e 10 mil operações de cada categoria acima = R$ 0,9503, aproximadamente R$ 0,95, antes de eventual tráfego/impostos/diferenças da oferta. Estado esperado muito menor que 1 GB. Reservar R$ 2 de créditos para esta etapa e acompanhar o realizado; não é teto técnico nem garantia de cobrança. Não foram criados encryption scopes nomeados nem Blob Inventory. Preços das VMs serão verificados antes das etapas que as criam, sem pressupor validação já feita.

Fonte: Azure Retail Prices API, filtro região brazilsouth, produto General Block Blob v2, Consumption, moeda BRL. [Referência da API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices).
