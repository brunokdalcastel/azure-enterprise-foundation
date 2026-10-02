# Case prático — da implantação à remoção

## Problema e solução

Usei a empresa fictícia Contoso Brasil como cenário para construir uma base Azure para uma aplicação interna. Meu objetivo foi praticar a implantação com Terraform e verificar, na prática, como rede, governança, permissões e monitoramento trabalham juntos. O laboratório foi realizado em uma conta gratuita do Azure (Free Trial), utilizando os créditos disponíveis e mantendo o limite de gastos ativo.

A foundation ficou em North Central US após restrições de SKU na região inicialmente proposta. O backend permaneceu em Brazil South. A aplicação foi IIS em Windows Server 2019 Core, em VM B2ats_v2 com Trusted Launch. Duas subnets e NSGs limitaram os fluxos; Azure Policy bloqueou região, SKU e ausência de tags. Quatro personas de identidade gerenciada permitiram testar RBAC sem publicar credenciais.

## Resultados e evidências

| Área | Resultado observado | Evidência |
|---|---|---|
| Estado e governança | Backend remoto e lock testados; Policies e tags verificadas | [Bootstrap](03-preparacao-bootstrap.md), [governança](04-governanca-rede.md) |
| Windows/IIS | HTTP 200, configuração do guest e acesso administrativo controlado | [Windows](07-evidencias-windows-iis.md) |
| RBAC e segmentação | 12 testes RBAC, HTTP privado permitido e tráfego lateral bloqueado | [RBAC](08-rbac-segmentacao.md) |
| Operação | Alertas reais, interrupção/recuperação do IIS e regra de rede Allow → Deny → Allow | [Incidentes](09-operacao-incidentes.md) |

## Decisões e limites

- Infraestrutura de laboratório, sem promessa de alta disponibilidade ou prontidão para produção.
- Personas de serviço não comprovam grupos humanos, MFA ou login interativo.
- O diagnóstico IP flow da Parte 6 complementa os testes de tráfego real da Parte 5.
- Disparos de métricas foram observados no Azure e a entrega por e-mail foi confirmada em um teste complementar de Activity Log. A entrega dos alertas de CPU anteriores não foi comprovada. A restrição da API de notificação de teste não impediu o recebimento do alerta real; nenhum upgrade foi realizado.
- Não houve GitHub Actions; execução local com revisão de planos foi suficiente para o escopo.
- Recursos temporários foram removidos após os blocos. Uma interrupção deixou disco, IP e monitoramento ativos entre sessões; desalocar a VM não eliminou esse consumo potencial. O custo efetivo e o saldo final não foram apurados.

## Remoção dos recursos

O Terraform concluiu 35 remoções na foundation, incluindo o marcador de validação do backend. O estado remoto vazio foi salvo localmente antes da exclusão do backend. Em seguida, o bootstrap concluiu 4 remoções: permissão de escrita do estado criada pelo laboratório, container, Storage e grupo de recursos. O estado local do bootstrap ficou sem recursos gerenciados. Cópias anteriores e finais dos estados ficam somente no diretório local ignorado pelo Git.

Os dois Network Watchers foram criados automaticamente durante a implantação das redes e estavam fora do estado Terraform. Antes de removê-los, conferi sua origem e confirmei que não havia VNets ou flow logs dependentes. Essa verificação complementou a limpeza feita pelo Terraform.

A exclusão terminou e o inventário final retornou **zero recursos Azure e zero grupos de recursos**. As três Policies do laboratório e a role customizada de energia também não existem mais. O orçamento preexistente foi preservado; conta, assinatura e acessos preexistentes não foram excluídos. A assinatura permaneceu Enabled, FreeTrial_2014-09-01, spending limit On.

[Evidência final sanitizada](part7-results.json). `terraform fmt -check` e `validate` dos dois roots passaram. Não foi executado um plano normal para recriar a infraestrutura após o encerramento: o backend remoto deixou de existir. A ausência de recursos foi comprovada por estado e inventário Azure. Isso não apura nem elimina consumo histórico dos créditos.

## Como reproduzir

O código permanece disponível após a destruição. Começar novamente pelo bootstrap e seguir os exemplos e documentos, revendo assinatura, créditos, preços, permissões, região, quota, imagem e IP autorizado. Valores locais, senha, destinatário de alertas e backend devem ser configurados para a nova execução. Não reutilizar planos salvos nem aplicar automaticamente um laboratório já encerrado.

## Validação final das notificações

Após os testes originais, um diagnóstico isolado criou somente um grupo de recursos, um Action Group e uma regra de Activity Log. Uma alteração de tag pelo Terraform gerou o evento monitorado e o alerta chegou por e-mail, com regra e recurso correspondentes. O teste demonstrou o funcionamento da entrega sem recriar uma VM.

Os três recursos foram destruídos após a validação. Uma nova consulta independente confirmou zero recursos e zero grupos na assinatura. O laboratório está concluído; os resultados anteriores continuam preservados como registros de cada etapa. A evidência complementar está em [notification-delivery-results.json](notification-delivery-results.json).
