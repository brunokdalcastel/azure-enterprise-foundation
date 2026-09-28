# Parte 3 — Governança e rede

Concluída em 2026-09-22: 34 recursos Terraform adicionados à foundation. Após as correções documentadas abaixo, plano final sem diferenças (exit code 0). Não foram criadas VMs.

## Resultados finais
- scripts/Test-Foundation.ps1 passou: RGs/tags, nove assignments, subnets sem saída implícita, NSGs associados, seis regras por NSG, RDP fechado e efeitos de Policy corretos.
- fmt/validate e exclusões de tfvars, planos e logs locais verificados; lock file do provider gerado.
- Região proibida bloqueada por af-region em ARM validate; tags Audit não bloquearam template sem tags. Sem implantação de recursos de teste.
- Budget preexistente preservado. Não foi criada duplicata nem configurado novo destinatário.
- Azure criou automaticamente NetworkWatcher_brazilsouth em NetworkWatcherRG; sem flow logs. Fora do estado Terraform, deve entrar na conferência de teardown e ser removido apenas se dedicado ao lab. Nenhum teste de pacote/fluxo real foi realizado nesta etapa.
- Assinatura Enabled com spending limit On ao término. Nenhum upgrade ou alteração de cobrança.

## Decisões implementadas no código
- Três RGs separados por responsabilidade: network, workload e operations, todos Dev/Brazil South com cinco tags.
- VNet 10.10.0.0/16; application 10.10.20.0/24 e test 10.10.40.0/24. Saída implícita desabilitada; saída explícita será configurada junto às VMs na Parte 4.
- Um NSG por subnet. Permitir somente HTTP entre os IPs planejados da VM de teste e do IIS; bloquear outros fluxos laterais. Permitir DNS, HTTP/HTTPS e NTP de saída; bloquear demais saídas.
- Sem VM/NIC/IP público, peering, NAT Gateway, Firewall pago, DDoS dedicado ou flow logs nesta etapa. Não há teste de conectividade real até existirem VMs.
- `admin_access_enabled=false`: nenhuma regra de RDP aberta nesta etapa. Na Parte 4, ativação apenas com origem administrativa /32 previamente validada.
- Três definições de Policy customizadas, nove assignments (três por RG). Region Deny, VM SKU Deny (Standard_B2s_v2), tags Audit. Definições existem na assinatura, assignments apenas nos RGs da foundation, sem atingir bootstrap.
- Tags usam modo Indexed e comparam valores esperados; subnets/associações sem suporte a tags não são forçadas. Audit não impede deploy; mudança para Deny virá após exercício de governança.

## Budget existente: preservar
A API confirmou um Budget anterior ao código desta etapa: `laboratorio-mensal-50-brl`, R$ 50/mês, notificações ativas a 50%, 80% e 100%, cada uma com um destinatário. Não publicar endereço. Consumo retornado na consulta: R$ 0,00 (dado sujeito a atraso, não comprova consumo zero em tempo real).

O Budget foi mantido sem alterações, duplicação ou importação automática para Terraform. É controle externo preexistente, não recurso criado por esta foundation; `terraform destroy` não o removerá. O valor é aviso antecipado e não representa limite autorizado de uso dos créditos. O laboratório utilizou créditos do Free Trial, sem upgrade para pagamento conforme o uso. Entrega de e-mail por gasto real ainda não testada; não gerar gasto proposital para atingir threshold.

## Custos
A VNet básica é gratuita; este desenho não inclui serviços de rede pagos. RGs, NSGs e policies de recursos Azure não acrescentam a cobrança de VM ou appliances. O backend continua consumindo pequenas quantidades de Storage/operações. [Preço da VNet](https://azure.microsoft.com/en-us/pricing/details/virtual-network/).

## Verificação reproduzível
```powershell
terraform '-chdir=foundation' fmt '-check'
terraform '-chdir=foundation' validate
terraform '-chdir=foundation' plan '-input=false' '-detailed-exitcode'
# Somente validação ARM, NÃO usar deployment create para este teste:
az deployment group validate --resource-group rg-network-dev-brs-01 --template-file tests/region-policy.json --name validate-region-denied
```

Esperado: RequestDisallowedByPolicy associado à assignment de região do laboratório; nenhum NSG é criado pelo validate. Eventual restrição regional herdada não substitui evidência da policy do projeto. Atribuições novas podem demorar a propagar.

Validações executadas em 22/09: template East US rejeitado com RequestDisallowedByPolicy e referência à assignment af-region. Template tests/tags-audit-policy.json, em Brazil South e sem tags, aceito por ARM validate; isso demonstra o comportamento não bloqueante de Audit, mas não comprova um registro de non-compliance (nenhum recurso sem tags foi efetivamente criado). Exercício de recurso não conforme e transição Audit → Deny permanece para governança/troubleshooting posterior.

## Correção durante o apply
Azure rejeitou quatro regras de bloqueio com SecurityRuleParameterContainsInvalidPortRanges: wildcard `*` não é aceito em destination_port_ranges. Código corrigido para destination_port_range em portas únicas/wildcard e destination_port_ranges somente para múltiplas portas explícitas. fmt/validate locais não detectaram essa restrição da API. As associações de subnet dependem de todas as regras, evitando associar o conjunto incompleto. Não havia VMs/NICs nas subnets durante a correção.

## Segurança e operações
Incidente real: após mudança de dia, backend retornou 403 AuthorizationFailure antes de criar recursos. Azure CLI ainda autenticada, Storage Succeeded/Deny e role de dados presente. A consulta do endereço de saída confirmou que o IPv4 público havia mudado.

Correção: atualizar somente a regra individual de IP pelo plano de gerenciamento do Azure (para recuperar acesso ao plano de dados), atualizar tfvars locais de bootstrap/foundation e reconciliar bootstrap via Terraform. O plano de reconciliação alterou apenas network_rules; não foram habilitadas chaves, acesso anônimo ou regra Allow para todos. Leitura do blob voltou a funcionar. O plano da foundation foi regenerado após recuperação.

Aprendizado: autenticação/RBAC e firewall são verificações separadas. Um executor com Owner pode ser bloqueado no plano de dados do Storage quando seu IP muda. Em sessões futuras, conferir essa hipótese antes de ampliar permissões. Sessão Azure permaneceu Free Trial Enabled com spendingLimit On.

Não excluir o Budget existente ao desmontar o laboratório sem pedido explícito. As definições customizadas de Policy estão no estado da foundation e serão removidas por Terraform após as assignments. Preservar bootstrap até destruir foundation.
