# Parte 6 — Operação e incidentes

## Escopo
Uma VM Windows/IIS temporária, duas regras de métricas Azure Monitor e um Action Group com destinatário autorizado, guardado somente em variáveis locais. Sem Log Analytics, AMA ou VM Insights. Assinatura Free Trial com spending limit On reconfirmada em 28/09/2026; nenhum upgrade realizado. Recursos podem consumir créditos.

## Alertas: evidências observadas
Horários abaixo em UTC. O histórico foi consultado em 28/09/2026.

| Teste | Evidência | Limite da conclusão |
|---|---|---|
| CPU | Alerta disparou em 24/09 às 16:29:21 e resolveu às 16:43:33. Limiar de ensaio: média maior que 5%, janela de 5 minutos, avaliação a cada minuto. Amostras de 1 minuto chegaram a 29,21% no período consultado. | O disparo ocorreu durante a inicialização/configuração; o script de carga limitada foi preparado, mas não executado. |
| Disponibilidade da VM | Alerta disparou em 25/09 às 01:04:02, após o desligamento automático das 22h de São Paulo. A série VmAvailabilityMetric apresentou mínimo 0. | Disponibilidade da VM não equivale à saúde do IIS. |
| Notificação de teste | API do Action Group retornou HTTP Conflict: `Free subscription not supported`. | Nenhum upgrade foi feito para contornar a restrição. Disparo do alerta não comprova recebimento do e-mail; entrega ainda não comprovada naquela etapa; ver validação complementar abaixo. |

O limiar padrão de CPU no código é 80%. `scripts/Invoke-BoundedCpuLoad.ps1` é uma ferramenta opcional de ensaio, não uma evidência de execução nesta etapa.

## Incidente de aplicação
`scripts/Test-IISIncident.ps1` verificou HTTP local 200, parou o serviço W3SVC e restaurou-o em um bloco `finally`. Resultado em 28/09: HTTP antes 200; durante, nenhuma resposta HTTP bem-sucedida; depois 200; serviço restaurado. O valor 0 no resultado do script representa falha de acesso, não um código HTTP real. A VM continuou ligada durante o teste.

Diagnóstico: uma VM ligada pode hospedar uma aplicação indisponível. Verificar o serviço e a resposta HTTP complementa a métrica de disponibilidade da plataforma.

## Incidente de rede
O parâmetro `http_test_access_enabled`, normalmente `true`, permite um ensaio reversível via Terraform: a regra privada de HTTP muda de Allow para Deny, mantendo origem, destino e porta. O Network Watcher `test-ip-flow` consulta o fluxo TCP de 10.10.40.10:50000 para 10.10.20.10:80. É diagnóstico de regras, não tráfego real; o tráfego entre duas VMs já foi testado na Parte 5.

Em 28/09, o diagnóstico retornou Allow antes da alteração, Deny durante o incidente e Allow após a restauração, sempre pela regra `securityRules/allow-test-http-in`. O Activity Log registrou `Microsoft.Network/networkSecurityGroups/securityRules/write` com Succeeded às 14:42:41 UTC. A restauração via Terraform alterou somente essa regra. O limiar de CPU também foi restaurado a 80% antes da limpeza.

Evidências sanitizadas: [resultados da Parte 6](part6-results.json). A consulta final ainda mostrava o alerta de disponibilidade em Fired e um novo disparo de CPU em 28/09 às 14:40:05 UTC, anterior à restauração do limiar. Não foi comprovada a resolução desses dois eventos antes da limpeza.

## RBAC e Policy no troubleshooting
As evidências reais de autorização e bloqueio estão em [Parte 5](08-rbac-segmentacao.md). Para um HTTP 403 do plano de controle, verificar principal, ação, escopo e role assignment. Para `RequestDisallowedByPolicy`, identificar a assignment/definition e comparar região, SKU e tags com o código. Não ampliar permissões nem desabilitar políticas apenas para eliminar o erro.

## Reprodução e limpeza
1. Conferir assinatura, limite de gastos, créditos, custos, quota e IP do backend.
2. Habilitar workload e monitoramento em variáveis locais; configurar e-mail autorizado. Revisar o plano antes de aplicar.
3. Consultar métricas e histórico dos alertas, distinguindo condição disparada de entrega de notificação.
4. Executar o incidente IIS. Para a rede, aplicar `http_test_access_enabled=false`, consultar IP flow e restaurar `true` pelo Terraform.
5. Restaurar CPU a 80%, desabilitar monitoramento/workload, revisar o plano de remoção e aplicar. Verificar discos, IPs, NICs, alertas e Action Group.
6. Manter o backend até a Parte 7; destruir foundation antes de remover o armazenamento do estado.

Houve interrupção entre 24 e 28/09: a VM foi desligada automaticamente, mas disco, IP e monitoramento permaneceram. Não foi apurado o consumo efetivo desse intervalo. Desalocar não equivale a eliminar custos.

## Resultado da limpeza em 28/09/2026
Terraform concluiu 8 remoções: VM (com disco do sistema), extensão IIS, NIC, IP público, agendamento de desligamento, dois alertas e Action Group. Consultas independentes confirmaram zero recursos nos RGs workload e operations, zero discos e zero IPs públicos no RG workload. `Test-Foundation.ps1` passou; `terraform fmt -check` e `validate` dos dois roots passaram. Rede, Policies e backend permanecem para a Parte 7. Naquela etapa, o recebimento dos e-mails ainda não havia sido comprovado.

Plano final: detailed-exitcode 0, sem diferenças após a limpeza.

## Validação complementar de entrega

Para validar a entrega sem manter uma VM em execução, usei um diagnóstico temporário com três recursos gerenciados por Terraform: grupo de recursos, Action Group com e-mail e regra de Activity Log. A regra observava a operação `Microsoft.Resources/subscriptions/resourceGroups/write`, categoria `Administrative`, com status `Succeeded`, no próprio grupo de recursos.

Após a verificação do destinatário, alterei uma tag pelo Terraform. O Azure registrou o disparo às 20:20:43 UTC e a ação de notificação no mesmo segundo. O Gmail recebeu a mensagem às 20:20:49 UTC. O assunto e o corpo correspondiam à regra e ao recurso; SPF, DKIM e DMARC passaram. A mensagem de inclusão no grupo foi tratada separadamente do alerta real.

Isso confirma a entrega ponta a ponta de um alerta de Activity Log pelo novo Action Group. Não comprova a entrega dos alertas de CPU anteriores nem determina a causa da ausência dessas mensagens. A restrição `Free subscription not supported` ocorreu na API de notificação de teste; não deve ser interpretada como bloqueio geral ao envio de alertas reais na assinatura.

Para reproduzir o diagnóstico, configure um destinatário próprio, conclua a verificação recebida por e-mail, crie a regra com o escopo e a operação acima e aguarde sua ativação antes de alterar uma tag. Compare o histórico do alerta com a mensagem recebida, incluindo spam e outras categorias da caixa postal. Revise o plano de destruição e remova os três recursos ao terminar. Esse diagnóstico foi independente da foundation e não integra sua implantação padrão.

A limpeza removeu os três recursos e a consulta independente retornou zero recursos e zero grupos na assinatura. [Evidência sanitizada](notification-delivery-results.json). Os JSON das Partes 6 e 7 preservam o resultado histórico das respectivas etapas.
