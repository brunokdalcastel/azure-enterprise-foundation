# Azure Enterprise Foundation — etapas do projeto

## Objetivo

Construir e testar uma base Azure para uma aplicação Windows interna, usando a Contoso Brasil como cenário fictício. O projeto percorre arquitetura, infraestrutura como código, segurança, operação e remoção dos recursos.

A execução foi realizada em uma conta gratuita do Azure (Free Trial), com créditos disponíveis e limite de gastos ativo. O ambiente já foi removido; este roteiro organiza a documentação para quem quiser estudar ou reproduzir o laboratório.

## Desenho implementado

- Terraform executado localmente, com código e evidências no GitHub.
- Foundation em North Central US e backend em Brazil South.
- Grupos de recursos separados para rede, aplicação, operação e estado.
- VNet 10.10.0.0/16, subnets application e test, com NSGs por subnet.
- Windows Server 2019 Core com IIS; VM auxiliar temporária para os testes de rede e permissões.
- Backend Storage com autenticação Entra ID; bootstrap separado e com estado local.
- Azure Policy para região, tamanho de VM e tags; RBAC com personas de identidade gerenciada.
- Métricas e alertas de CPU e disponibilidade, sem Log Analytics.

A região e a versão do Windows foram ajustadas durante a implantação devido às restrições de disponibilidade da assinatura. As propostas anteriores e suas revisões estão preservadas nos documentos técnicos.

## Etapas e resultados

| Parte | Entrega | Resultado |
|---|---|---|
| 1 — Arquitetura | Requisitos, fluxos, naming, tags, acesso e custos | Desenho documentado e ajustado conforme as verificações da assinatura |
| 2 — Preparação e bootstrap | Ferramentas, Storage e backend remoto | Gravação e lock do estado confirmados; bootstrap com estado local |
| 3 — Governança e rede | Grupos, Policies, VNet, subnets e NSGs | Configuração verificada e teste de região proibida bloqueado |
| 4 — Windows e IIS | VM, configuração da aplicação e testes do sistema | HTTP 200 e controles de acesso verificados; workload removido após testes |
| 5 — RBAC e segmentação | Personas, permissões e testes entre VMs | 12 testes RBAC, HTTP privado, bloqueio lateral e Policies validados; temporários removidos |
| 6 — Operação e incidentes | Métricas, alertas, Activity Log e troubleshooting | Disparos reais e recuperação de IIS/rede comprovados; entrega de e-mail não confirmada |
| 7 — Encerramento e portfólio | Evidências, documentação e destruição | Foundation e backend removidos; inventário final sem recursos ou grupos de recursos |

## Como usar o roteiro

Comece pelo [README](README.md) e siga os documentos de cada etapa. Eles explicam decisões, resultados e limitações observadas na execução. Configure seus próprios valores locais antes de reproduzir e confira região, quota, imagem, custos e condições da assinatura.

Habilite somente os blocos necessários ao teste atual. Revise o plano antes de aplicar, registre as evidências e remova os recursos temporários ao terminar. Para recriar o ambiente completo, comece pelo bootstrap: o backend original não existe mais.

## Créditos e limpeza

O uso de Free Trial não torna todos os serviços gratuitos. VMs, discos, IPs, Storage e monitoramento podem consumir créditos. A execução original manteve o limite de gastos ativo e não fez upgrade para pagamento conforme o uso. Os valores efetivamente consumidos não foram apurados.

Destrua a foundation enquanto o backend ainda estiver acessível, preserve o estado final localmente e remova o bootstrap por último. Confira também recursos automáticos fora do Terraform. Preserve recursos e acessos preexistentes que não pertençam ao laboratório.

## Limitação que permanece

Os alertas dispararam no Azure, mas o recebimento do e-mail não foi confirmado. A API de notificação de teste retornou uma restrição da assinatura gratuita. Esse ponto permanece separado dos testes técnicos concluídos e não deve ser apresentado como entrega de notificação validada.
