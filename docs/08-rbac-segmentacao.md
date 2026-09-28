# Parte 5 — RBAC e segmentação

Concluída em 24/09/2026: testes aprovados e 22 recursos temporários removidos. Resultados abaixo distinguem execução real de validação de templates.

## Desenho do teste
Duas VMs Windows Server 2019 Core B2ats_v2, 2 vCPUs/1 GiB cada, ocupam a quota regional de 4 vCPUs. Web em 10.10.20.10 e test em 10.10.40.10. Ambas usam IP Standard para saída explícita; nenhuma regra de entrada RDP pública é aberta nesta fase. Administração de teste pelo Run Command do executor.

Quatro identidades gerenciadas temporárias representam as personas. Isso substitui, neste laboratório, grupos Entra e login humano propostos inicialmente. Testa Azure RBAC com autenticação real por identidade, mas não testa grupos, MFA nem experiência de login de pessoas. Todas as identidades são ligadas à VM test, que é executora privilegiada e descartável; qualquer administrador dessa VM pode obter seus tokens. Não usar este arranjo como isolamento entre usuários em produção.

| Persona | Atribuições temporárias |
|---|---|
| Rede | Network Contributor no RG network |
| Analista | Virtual Machine Contributor no RG workload; Reader no RG network |
| Desenvolvedor | Role customizada de leitura/start/restart/deallocate apenas na VM web; Reader no RG workload |
| Auditor | Reader nos três RGs foundation |

Nenhuma credencial de aplicação é criada. Tokens vêm do IMDS na VM test e não são escritos nas evidências. A VM test é usada apenas pelo executor. As identidades, atribuições e role customizada são removidas após os testes.

## Critérios
- HTTP privado test→web retorna 200 e a página esperada.
- RDP/SMB lateral não conectam; corroborar negação com regras efetivas.
- Rede pode escrever tags idênticas na VNet, mas não ler workload.
- Analista pode ler/escrever tags idênticas da VM, mas não escrever na rede.
- Desenvolvedor pode reiniciar web; alterações de rede e Run Command retornam 403 AuthorizationFailed.
- Auditor lê VM, mas escrita na VM/rede retorna 403 AuthorizationFailed.
- Testar Policy de SKU proibido e evolução de tags Audit→Deny sem criar compute adicional.
- Destruir todo workload temporário e identidades; plano final sem diferenças.

PATCHs usam as tags existentes, sem mudar o conteúdo nem as regras de tráfego. Uma falha por Policy não conta como teste RBAC negativo: exigir AuthorizationFailed. Reiniciar a VM web é uma operação real e controlada, feita após os testes de tráfego.

## Custos
Cotação BRL North Central US em 24/09: Windows B2ats_v2 R$ 0,0962/h fora do benefício, IP R$ 0,0259/h, E4 LRS R$ 12,4082/mês mais operações. Par ligado ~R$ 0,2782/h com rateio de disco em 730h, antes de tráfego/diagnóstico/operações. Não representa consumo realizado nem saldo de horas gratuitas. Free Trial Enabled e spending limit On verificados. Sem upgrade.

## Fontes
[Tokens IMDS](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-use-vm-token), [roles Compute](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/compute).

## Resultados observados
- 12 testes RBAC passaram com tokens reais das quatro identidades: leituras/escritas autorizadas HTTP 200; reinício HTTP 202; todos os seis testes negativos HTTP 403 AuthorizationFailed. Resultados sanitizados em [JSON RBAC](part5-rbac-results.json).
- Activity Log confirmou um evento restart/action Succeeded e o object ID do ator igual ao da persona developer. IDs não publicados. Ingestão demorou alguns minutos; o primeiro resultado vazio não foi tratado como falha definitiva.
- HTTP real da test para web: 200 e conteúdo Contoso Brasil. TCP RDP e SMB lateral sem conexão. Teste repetido após reinício com os mesmos resultados: [JSON segmentação](part5-segmentation-results.json).
- IP flow confirmou RDP lateral negado pela regra de saída deny-other-out. Não atribuir o timeout exclusivamente ao Windows Firewall nem alegar teste isolado de todas as camadas.
- Auditoria das atribuições: rede 1, analista 2, desenvolvedor 2, auditor 3; nenhum Owner/Contributor genérico/User Access Administrator nas personas.
- ARM validate: SKU Standard_D2as_v6 bloqueado por af-vm-sku. Nenhuma VM desse tamanho foi implantada.
- ARM validate: sem tags aceito em Audit; após alteração Terraform para Deny, recusado por af-tags. Template com tags corretas na região permitida aceito. Não foi criado recurso sem tags nem comprovado evento Audit non-compliant.
- Policy tags permanece Deny; todos os recursos mantidos possuem as tags exigidas. Os testes de escrita idempotente nas tags não deixaram mudança de conteúdo.

## Limites e reprodução
Inventário final: zero recursos no RG workload, zero identidades de teste, zero discos/IPs públicos, zero atribuições das personas e zero roles Lab VM Power Operator. Test-Foundation PASS, fmt/validate OK, spending limit On. Tags Deny permanece como melhoria de governança; backend Storage permanece necessário até encerramento e pode consumir créditos.

As identidades são personas de serviço, não contas humanas: membership de grupos Entra, MFA e login interativo não foram testados. A VM test concentra as quatro identidades somente para laboratório controlado e descartável.

Para reproduzir: habilitar workload_enabled e part5_enabled, manter admin_access_enabled=false; aplicar plano revisado; executar Test-Segmentation.ps1 na VM test; preencher o placeholder do template Test-Personas.ps1.tftpl com client IDs/IDs dos recursos/tags, em arquivo local ignorado; executar por Run Command como executor. Tokens ficam somente na memória do guest e jamais nos resultados. Ao concluir, desabilitar part5/workload, aplicar plano de destruição e verificar inventários de recursos e acessos.

Plano final após limpeza: detailed-exitcode 0, No changes. Nenhuma execução pendente.
