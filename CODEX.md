# Kobold — Handoff técnico para Codex
## Fedora Silverblue + Finpilot como fábrica, sem Bluefin no sistema

> Este arquivo é a especificação de implementação do projeto **Kobold**.
>
> O objetivo é criar uma workstation bootc enxuta, previsível, segura e eficiente,
> baseada diretamente no Fedora Silverblue oficial, usando Finpilot apenas como
> infraestrutura de composição/build/CI onde isso for útil.
>
> Os repositórios locais **Pinguim** e **Akatsuki** devem ser usados como fontes
> práticas de configuração e validação. Não reconstruir decisões já validadas por
> memória quando elas puderem ser copiadas e comparadas diretamente nesses repos.

---

# 1. Objetivo

Criar o projeto **Kobold** com esta cadeia conceitual:

```text
Fedora Silverblue oficial
          ↓
Finpilot / scaffolding de build e CI
          ↓
Kobold
```

O sistema instalado NÃO deve herdar a experiência Bluefin.

Não usar como camada do sistema:

- Bluefin;
- `projectbluefin/common`;
- Universal Blue base images;
- Brew/Homebrew;
- Bazaar;
- Bluefin DX;
- Docker;
- RPM Fusion;
- branding Bluefin;
- serviços ou políticas Bluefin;
- Flatpaks pré-instalados pelo ecossistema Bluefin.

## Regra

Finpilot entra como **fábrica**, não como **produto**.

Se a versão atual do Finpilot exigir componentes Bluefin para funcionar, não
adicioná-los silenciosamente. Verificar a documentação/README upstream atual e:

1. usar apenas as partes do Finpilot que funcionam sobre Silverblue oficial; ou
2. adaptar/copiar a infraestrutura genérica de build, CI, pinning, Renovate e
   testes para o repositório Kobold.

Não aceitar uma dependência Bluefin apenas para poder dizer que o projeto “usa
Finpilot”.

---

# 2. Fontes locais obrigatórias

Na pasta de trabalho existirão os projetos anteriores:

```text
Pinguim
Akatsuki
Kobold
```

Os nomes reais das pastas podem variar. Localizá-los antes de trabalhar.

## Pinguim

É a principal referência para:

- hardening validado;
- comportamento térmico validado;
- TuneD/tuned-ppd;
- Wi-Fi powersave;
- áudio powersave;
- ZRAM e tuning de memória;
- firewall;
- Bluetooth `AutoEnable=false`;
- Podman/Distrobox;
- QEMU/KVM/libvirt;
- Niri;
- VS Code RPM Microsoft;
- `pinguim doctor`;
- configurações que já funcionaram no ThinkPad T495.

## Akatsuki

Usar apenas como referência de engenharia para:

- scripts pequenos e bem delimitados;
- `set -euo pipefail`;
- checks estáticos;
- invariantes de imagem;
- validação de vendor;
- verificação de credenciais;
- limpeza segura da imagem;
- separação entre OCI, QCOW2 e ISO;
- CI/release quando aplicável.

Não copiar decisões do Akatsuki que existiam por causa de Bluefin/Finpilot
específico daquela versão.

---

# 3. Antes de escrever código

O Codex deve primeiro inspecionar os três contextos:

1. repositório Pinguim;
2. repositório Akatsuki;
3. upstream atual do Finpilot.

Não começar criando arquivos imediatamente.

Localizar no Pinguim pelo menos:

```text
Containerfile
scripts/
files/
stable.digest
README.md
```

Identificar os arquivos reais correspondentes a:

```text
hardening sysctl
sudoers hardening
sshd hardening
TuneD
NetworkManager Wi-Fi powersave
snd_hda_intel audio powersave
zram-generator
Bluetooth main.conf
firewall configuration
services configuration
Niri
VS Code install
pinguim doctor
virtualization
```

No Akatsuki, localizar:

```text
build scripts
static checks
image invariants
vendor checks
credential checks
final cleanup
CI
installer/ISO organization
```

No Finpilot atual, verificar:

- imagem base usada;
- forma de pinning por digest;
- Renovate;
- workflows;
- build/push para GHCR;
- assinatura, caso já exista infraestrutura genérica útil;
- quais partes são realmente genéricas;
- quais partes dependem de Bluefin/common/Brew/Bazaar.

---

# 4. Base do sistema

Usar **Fedora Silverblue oficial** diretamente.

A referência histórica validada é:

```Dockerfile
ARG BASE_IMAGE=quay.io/fedora-ostree-desktops/silverblue:44
FROM ${BASE_IMAGE}
```

## Digest pinning

Não depender apenas de tag mutável para builds reproduzíveis.

Preferir:

```Dockerfile
FROM quay.io/fedora-ostree-desktops/silverblue:44@sha256:<digest>
```

ou o mecanismo equivalente usado pelo Finpilot atual.

Renovate pode acompanhar o digest da base.

## Upgrade de Fedora

Não misturar:

```text
criação do Kobold
+
migração Fedora 44 → versão seguinte
```

Primeiro criar e validar a baseline sobre a mesma geração Fedora usada como
referência do Pinguim.

Depois, upgrade de major Fedora deve ser uma mudança separada e testável.

---

# 5. Filosofia upstream-first

Regra central:

> Se o Fedora Silverblue já resolve corretamente, não customizar.
>
> Se o Pinguim demonstrou benefício real e validado no T495, preservar.

Preferir upstream para:

- GNOME;
- GDM;
- Nautilus;
- PipeWire;
- WirePlumber;
- portals;
- GNOME Keyring;
- fingerprint/fprintd;
- firmware;
- fwupd;
- microcode;
- systemd;
- systemd-oomd;
- Flatpak;
- GNOME Software;
- hardware discovery;
- USB autosuspend;
- Bluetooth stack.

Não escrever configuração própria apenas para “controlar mais”.

---

# 6. Identidade e branding

Zero rebranding.

Não alterar:

```text
/usr/lib/os-release
Fedora logos
GDM branding
Plymouth
wallpapers
vendor strings
GNOME branding
hostname global
```

O projeto/imagem pode se chamar:

```text
Kobold
```

mas a identidade técnica permanece Fedora Silverblue.

---

# 7. GNOME mínimo

GNOME é o desktop principal.

Manter a infraestrutura GNOME upstream intacta.

## Aplicações básicas que devem permanecer

```text
nautilus
gnome-software
ptyxis
gnome-text-editor
loupe
gnome-calculator
gnome-disk-utility
```

Funções:

- Nautilus: arquivos;
- GNOME Software: Flatpak/app store;
- Ptyxis: terminal;
- Text Editor: edição simples;
- Loupe: visualização de imagens;
- Calculator: cálculo;
- GNOME Disks: discos, partições, SMART, imagens e storage.

## Remoção conservadora de apps

Usar como candidatos, não como lista cega:

```text
gnome-tour
gnome-connections
gnome-contacts
gnome-maps
gnome-weather
gnome-calendar
gnome-clocks
gnome-characters
gnome-logs
gnome-font-viewer
snapshot
simple-scan
cheese
rhythmbox
totem
epiphany
geary
yelp
firefox
```

Para cada candidato:

1. verificar se está instalado;
2. remover individualmente;
3. usar `--no-autoremove`;
4. validar que GNOME/GDM não foram afetados;
5. se a remoção ameaçar componente estrutural, manter.

Não remover componentes essenciais apenas para diminuir `rpm -qa`.

---

# 8. Flatpak

Flatpak deve funcionar normalmente.

GNOME Software deve continuar sendo a interface preferida para instalação de
apps desktop.

## Primeiro boot

Não pré-instalar coleção de Flatpaks.

Firefox deve ser instalado manualmente pelo usuário via GNOME Software.

Também podem ser instalados depois via Flatpak:

- Camera/Snapshot;
- Document Scanner/Simple Scan;
- Calendar;
- Weather;
- Maps;
- Bitwarden;
- LibreOffice;
- demais apps desktop.

Não criar serviços/timers de first-boot para isso.

---

# 9. Firefox

Não instalar Firefox na imagem Kobold.

Se houver Firefox RPM na base e puder ser removido de forma segura, removê-lo.

Não portar:

```text
pinguim firefox
Firefox provision service
Firefox provision timer
Firefox policies próprias
```

Fluxo:

```text
Kobold instalado
      ↓
GNOME Software
      ↓
Firefox Flatpak
```

---

# 10. Niri

Manter Niri como sessão opcional.

GNOME continua principal.

Preservar inicialmente a baseline funcional do Pinguim.

Pacotes usados anteriormente podem incluir:

```text
niri
waybar
fuzzel
mako
swaylock
swayidle
swaybg
mate-polkit
brightnessctl
playerctl
wl-clipboard
```

Antes de fixar a lista, verificar a implementação real do Pinguim e os requisitos
da versão Fedora atual.

Não transformar o Niri em outro projeto de customização.

Objetivo:

```text
GDM
├── GNOME
└── Niri
```

---

# 11. VS Code oficial Microsoft

Manter o RPM oficial:

```text
code
```

## Supply chain

Preservar o padrão validado no Pinguim/Akatsuki:

1. obter chave Microsoft;
2. validar fingerprint;
3. importar chave;
4. configurar repo oficial Microsoft durante o build;
5. instalar/atualizar `code`;
6. validar vendor;
7. remover o arquivo `.repo` da imagem final se ele não for necessário no
   sistema instalado.

Fingerprint esperada:

```text
BC528686B50D79E339D3721CEB3E94ADBE1229CF
```

Vendor esperado:

```text
Microsoft Corporation
```

## Importante: atualizações do VS Code

Kobold é image-based.

Não é necessário deixar o repo Microsoft persistente no host para atualizar
VS Code via bootc.

Cada rebuild faz:

```text
build Kobold
   ↓
configura/verifica repo Microsoft
   ↓
dnf install/upgrade code
   ↓
remove repo do artefato final
   ↓
publica nova OCI
   ↓
bootc upgrade no notebook
```

Assim, o VS Code acompanha os rebuilds Kobold sem transformar a instalação
imutável em um host com repo externo usado por DNF diretamente.

Não depender do auto-updater interno do VS Code.

---

# 12. CLI mínima Dev/DevSecOps

Manter ferramentas universais:

```text
git
git-lfs
gh
curl
wget
jq
rsync
ripgrep
fd-find
bat
fzf
```

Confirmar nomes reais dos pacotes no Fedora usado.

Não encher o host de toolchains.

Preferir Distrobox/Podman para:

- Node.js;
- npm/pnpm/yarn;
- Python de projeto;
- Go;
- Rust;
- Terraform;
- OpenTofu;
- Ansible;
- kubectl;
- Helm;
- cloud CLIs;
- databases;
- frameworks;
- SDKs;
- ferramentas específicas de cliente/projeto.

---

# 13. Podman e Distrobox

Prioridade:

```text
rootless Podman + Distrobox
```

Baseline:

```text
podman
buildah
skopeo
distrobox
passt
slirp4netns
fuse-overlayfs
shadow-utils-subid
```

Manter `podlet` apenas se tiver utilidade real para Quadlet.

Não instalar:

```text
Docker
docker-cli
docker-compose
docker-ce
moby-engine
podman-docker
podman-compose
Homebrew
Linuxbrew
```

Não usar RPM Fusion.

Toolbox não é requisito. Não gastar engenharia só para removê-lo se estiver
presente e inerte; remover apenas se for seguro e simples.

---

# 14. Virtualização

Manter inicialmente o conjunto já validado no Pinguim.

Referência:

```text
qemu-kvm
libvirt-daemon-kvm
libvirt-daemon-config-network
virt-manager
virt-install
virt-viewer
edk2-ovmf
swtpm
swtpm-tools
dnsmasq
```

Não modularizar agressivamente QEMU/libvirt na primeira versão.

## Libvirt on-demand

Usar os daemons/sockets modulares fornecidos pelo Fedora atual quando
apropriado.

Não depender do daemon monolítico se o Fedora atual já usa a arquitetura
modular.

Verificar nomes reais das units antes de habilitar/mascarar.

## Zero VM autostart na imagem

Não copiar:

```text
/var/lib/libvirt
```

de máquina existente.

Não criar VM.

Não marcar VM para autostart.

`pinguim doctor` pode reportar autostart existente depois da instalação, mas
não deve alterá-lo.

---

# 15. SELinux

Obrigatório:

```text
Enforcing
```

Não:

- desabilitar;
- colocar permissive;
- adicionar AppArmor;
- enfraquecer política para contornar bug de build.

Resolver problemas no componente responsável.

---

# 16. Hardening

Copiar do Pinguim **os arquivos reais já validados**, não reescrever por memória.

Localizar e revisar:

```text
sysctl hardening
sudoers hardening
sshd hardening
```

Manter o conteúdo equivalente na baseline v0.1, salvo incompatibilidade real
com Fedora.

## Invariantes

A imagem não pode conter:

- usuário humano pré-criado;
- senha utilizável;
- root com hash utilizável;
- SSH host keys persistidas do build;
- `authorized_keys`;
- conexões NetworkManager pessoais;
- tokens;
- credenciais;
- auth.json de registry;
- secrets de CI.

Validar sintaxe de sudoers e sshd.

---

# 17. SSH

Pode manter pacote/config de OpenSSH endurecido para disponibilidade futura.

Mas:

```text
TCP/22 NÃO deve estar aberto por padrão.
```

Não expor sshd automaticamente.

Habilitar SSH server deve exigir ação explícita do usuário.

---

# 18. Firewall

Preservar a política já validada do Pinguim.

Objetivo:

```text
firewalld ativo
default zone = drop
zero inbound por padrão
```

A zona `drop` não deve conter serviços/rich rules inesperados.

Não habilitar masquerade/forward na zona default apenas por conveniência.

Redes virtuais libvirt podem manter a configuração de rede necessária em sua
própria zona.

---

# 19. Energia

Preservar a implementação comprovada no Pinguim:

```text
TuneD
tuned-ppd
```

Não instalar stack concorrente:

```text
TLP
auto-cpufreq
```

Não inventar kernel args novos.

Usar o perfil/mapeamento TuneD efetivamente existente no Pinguim como baseline.

O GNOME deve continuar conseguindo selecionar perfis pelo backend
`tuned-ppd`.

---

# 20. Wi-Fi

Preservar a configuração validada do Pinguim:

```ini
[connection]
wifi.powersave=2
```

Não adicionar mais tweaks de Wi-Fi sem evidência.

---

# 21. Áudio

Preservar a configuração validada do Pinguim:

```text
options snd_hda_intel power_save=0 power_save_controller=N
```

Manter PipeWire/WirePlumber upstream.

---

# 22. Bluetooth

Bluetooth deve permanecer instalado e integrado ao GNOME.

O rádio deve iniciar desligado.

Preservar:

```ini
[Policy]
AutoEnable=false
```

Objetivo:

```text
boot
 ↓
Bluetooth disponível
 ↓
radio OFF
 ↓
toggle GNOME pode ligar normalmente
```

Não mascarar `bluetooth.service`.

Não remover BlueZ.

Não criar toggle custom.

---

# 23. Fingerprint

Não customizar.

O suporte upstream do Fedora Silverblue funciona adequadamente no hardware
alvo.

Não adicionar:

- driver Goodix/TOD custom;
- PAM override próprio;
- script próprio.

Preservar o stack upstream.

---

# 24. USB autosuspend

Manter comportamento upstream Fedora.

Não adicionar:

```text
usbcore.autosuspend=-1
```

Não desabilitar autosuspend globalmente.

Só revisar mediante regressão real.

---

# 25. ZRAM e memória

Preservar a configuração real do Pinguim.

Baseline conhecida:

```ini
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
swap-priority = 100
```

Preservar também o tuning de memória do sysctl validado no Pinguim.

Não criar swapfile adicional.

Não instalar `earlyoom` por padrão.

Usar gerenciamento de OOM do Fedora/systemd.

---

# 26. fstrim, firmware, fwupd e microcode

Upstream-first.

Não duplicar mecanismos Fedora.

Durante testes verificar o estado real:

```bash
systemctl is-enabled fstrim.timer
fwupdmgr --version
```

Microcode/firmware devem seguir os pacotes e mecanismos oficiais Fedora.

Não criar script próprio para microcode.

---

# 27. Journald

Preservar a configuração validada do Pinguim:

```text
SystemMaxUse=300M
SystemKeepFree=250M
MaxRetentionSec=1month
```

---

# 28. Serviços opcionais

Revisar o Pinguim para identificar serviços que foram removidos/desabilitados
com sucesso.

Candidatos históricos podem incluir:

```text
cups
cups-browsed
ModemManager
avahi
bolt
geoclue2
mcelog
```

Não copiar cegamente.

Para cada serviço:

1. existe no Silverblue atual?
2. está ativo por padrão?
3. o hardware/uso precisa dele?
4. removê-lo quebra GNOME ou hardware?
5. existe ganho operacional real?

Preservar somente decisões ainda coerentes.

Bluetooth e fingerprint não entram nessa lista de remoção.

---

# 29. DNS e rede

Não portar a stack custom de DNS do Pinguim/Akatsuki para v0.1.

Usar comportamento padrão do Fedora Silverblue.

Não forçar:

- Cloudflare;
- Quad9;
- DNS-over-TLS;
- systemd-resolved custom;
- `/etc/resolv.conf` custom.

Isso reduz risco de regressão de Wi-Fi/rede.

Pode ser reavaliado depois como feature opcional separada.

---

# 30. Comando custom

Manter apenas:

```bash
pinguim doctor
```

Isso é deliberado mesmo com o projeto chamado Kobold.

Não criar outro CLI agora.

`pinguim doctor` deve ser:

- read-only;
- rápido;
- diagnóstico;
- sem reparo automático;
- sem instalação;
- sem update;
- sem alteração de firewall;
- sem alteração de energia.

## Checks

Implementar/portar checks para:

```text
Fedora identity
bootc status
SELinux enforcing
firewalld active
default zone drop
zero inbound default
TuneD
tuned-ppd
ZRAM
memory tuning expected
Wi-Fi powersave config
audio powersave config
Bluetooth available
Bluetooth AutoEnable=false
fingerprint upstream available
Podman rootless
subuid/subgid
Distrobox
KVM
libvirt
VS Code installed
VS Code vendor Microsoft Corporation
GNOME available
Niri available
GNOME Software
GNOME Disks
fstrim state
no Docker packages
no RPM Fusion release packages
no Brew
no embedded credentials
no persistent Microsoft repo if build-time-only design is used
```

Checks que dependem de runtime devem executar depois da instalação, não fingir
que foram validados no container build.

---

# 31. Estrutura de projeto

Manter pequena e previsível.

Sugestão:

```text
kobold/
├── Containerfile
├── build/
│   ├── 10-base.sh
│   ├── 20-packages.sh
│   ├── 30-vscode.sh
│   ├── 40-services.sh
│   ├── 50-hardening.sh
│   ├── 60-desktop.sh
│   ├── 70-hardware.sh
│   └── 90-finalize.sh
├── files/
├── tests/
│   ├── static-checks.sh
│   ├── image-invariants.sh
│   └── manual-checklist.md
├── installer/
├── tools/
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SECURITY.md
│   ├── UPDATE.md
│   └── RECOVERY.md
├── renovate.json
├── README.md
└── .gitignore
```

Adaptar aos padrões do Finpilot atual se isso reduzir código sem importar
Bluefin.

Não criar abstração apenas por estética.

---

# 32. Scripts

Todos os scripts shell próprios devem começar com:

```bash
set -euo pipefail
```

Regras:

- função única clara;
- mensagens úteis;
- sem esconder falhas;
- sem `|| true` generalizado;
- operações opcionais podem testar existência antes de executar;
- não executar mudanças destrutivas fora do contexto de build.

---

# 33. Checks estáticos

Portar a ideia do Akatsuki.

`tests/static-checks.sh` deve verificar, no mínimo:

- scripts válidos;
- arquivos referenciados existem;
- permissões esperadas;
- Containerfile aponta para scripts existentes;
- nenhum branding inesperado;
- nenhum secret óbvio;
- nenhum Docker/RPM Fusion/Brew adicionado;
- base Silverblue oficial;
- nenhum `projectbluefin/common`;
- nenhum `ghcr.io/ublue-os/bluefin*`;
- nenhum componente Finpilot que introduza runtime Bluefin.

---

# 34. Invariantes da imagem

Depois da composição, validar:

## Base/identidade

```text
Fedora
Silverblue/ostree desktop base
bootc container lint
```

## Apps essenciais

```text
nautilus
gnome-software
ptyxis
gnome-text-editor
loupe
gnome-calculator
gnome-disk-utility
niri
code
```

## Containers

```text
podman
distrobox
```

## Virtualização

```text
QEMU/KVM
libvirt
virt-manager
```

## Segurança

```text
SELinux config intact
firewalld
sudoers valid
sshd config valid
root locked
no human users
no SSH keys
no NM personal connections
no registry credentials
```

## Supply chain

```text
code vendor = Microsoft Corporation
Fedora packages from Fedora repos/vendors when relevant
base image digest pinned
```

## Proibidos

```text
Docker
RPM Fusion
Homebrew
Bluefin image
projectbluefin/common
Bazaar
```

---

# 35. Limpeza final

Reaproveitar a prudência do Pinguim/Akatsuki.

Remover:

- caches de build;
- metadata transitória;
- machine-id final conforme prática correta para imagem;
- random seed;
- SSH host keys;
- estado libvirt criado durante build;
- repo Microsoft se usado apenas para build;
- credenciais temporárias.

Não:

- remover `/run` cegamente;
- apagar container storage em uso;
- executar prune global;
- limpar dados do host runner fora do escopo do job.

---

# 36. Modelo de atualização

Este é um requisito central do Kobold.

O usuário NÃO quer precisar reconstruir/publicar manualmente toda semana.

Separar quatro conceitos:

```text
upstream tracking
candidate build
stable promotion
host installation
```

Eles não devem acontecer todos ao mesmo tempo.

---

# 37. Renovate e digest pinning

Configurar Renovate para acompanhar:

```text
quay.io/fedora-ostree-desktops/silverblue:44@sha256:...
GitHub Actions usadas pelo projeto
demais imagens de build necessárias
```

Preferir atualização de digest, não mudança automática de major Fedora.

## Política recomendada

Renovate pode abrir/atualizar PRs automaticamente.

Para updates simples de digest do Silverblue:

- executar CI completo;
- se todos os checks passarem, permitir merge automático para o branch de
  desenvolvimento/default apenas se a política atual do repo for segura;
- NÃO mover `stable` como consequência direta desse merge.

Se automerge gerar risco ou ruído, manter PR automática e usar merge agendado.
O ponto obrigatório é que `stable` tenha gate separado.

---

# 38. Canais de imagem

Publicar pelo menos:

```text
kobold:testing
kobold:stable
```

Opcional:

```text
kobold:<git-sha>
kobold:<date>
```

## testing

Atualiza quando:

- novo digest upstream é integrado;
- código Kobold muda;
- CI passa.

É candidato, não release para workstation principal.

## stable

Só recebe promoção de uma imagem `testing` já validada.

Não reconstruir um payload diferente durante promoção.

Preferir promoção/cópia pelo digest exato testado.

Assim:

```text
testing@sha256:ABC
        ↓
gate
        ↓
stable@sha256:ABC
```

e NÃO:

```text
testing build
        ↓
rebuild separado
        ↓
stable com outro digest
```

---

# 39. Cadência stable: aproximadamente 14 dias

Objetivo:

> receber atualizações acumuladas sem churn semanal.

Não depender de um cron “a cada 14 dias” frágil.

Implementar um workflow de promoção que:

1. rode em schedule regular, por exemplo diariamente ou semanalmente;
2. leia a data/digest da última promoção stable;
3. só promova automaticamente quando tiverem passado pelo menos 14 dias;
4. exija que exista candidate `testing` mais novo;
5. exija CI/invariantes verdes;
6. promova o digest testado;
7. registre metadata/release.

Alternativa aceitável mais simples:

```text
1º e 15º dia de cada mês
```

mas a lógica “>=14 dias desde última stable” é preferível porque lida melhor
com falhas e meses de tamanhos diferentes.

## GitHub Actions

Usar `schedule` e `workflow_dispatch`.

Scheduled workflows devem estar no default branch.

Não agendar exatamente no minuto 00 se puder evitar filas de alta carga.

Exemplo conceitual:

```yaml
on:
  schedule:
    - cron: "23 9 * * *"
  workflow_dispatch:
```

A checagem diária é barata se o workflow encerrar rapidamente quando ainda não
há 14 dias ou não há candidate novo.

---

# 40. Segurança: release extraordinária

Não tentar automatizar no primeiro momento a interpretação completa de CVEs.

Isso é complexo e pode produzir falso senso de segurança.

Implementar caminho claro para release extraordinária:

```text
Fedora corrige vulnerabilidade relevante
          ↓
Renovate/base digest update
          ↓
CI produz testing
          ↓
verificação
          ↓
workflow_dispatch
          ↓
promove testing → stable antes dos 14 dias
```

`workflow_dispatch` deve poder ignorar apenas o gate de idade.

Ele NÃO deve ignorar:

- build;
- static checks;
- image invariants;
- bootc lint;
- supply-chain checks.

## Critérios para promoção antecipada

Exemplos:

- kernel;
- glibc;
- systemd;
- sudo;
- OpenSSH;
- SELinux;
- Podman/container stack;
- boot chain;
- firmware;
- componente crítico realmente presente no Kobold.

Não criar release extraordinária para qualquer CVE de pacote irrelevante ou
não instalado.

---

# 41. Atualização do host

Não habilitar instalação automática de nova imagem no notebook na v0.1.

O GitHub pode publicar `stable`.

O notebook aplica quando o usuário decidir.

Fluxo:

```bash
bootc status
sudo bootc upgrade
reboot
```

Confirmar a sintaxe atual do bootc antes de documentar definitivamente.

Isso cria duas cadências independentes:

```text
publicação Kobold stable
~14 dias ou emergência

instalação no notebook
quando for conveniente
```

Não criar reboot automático.

Não aplicar update no meio do trabalho.

---

# 42. Relação entre VS Code e ciclo Kobold

VS Code acompanha o ciclo de imagem.

Exemplo:

```text
Kobold stable A
  └── code versão X

upstream Microsoft atualiza code

próximo candidate Kobold
  └── build-time repo instala code versão Y

Kobold stable B
  └── code versão Y
```

Logo:

- repo Microsoft pode ser temporário no build;
- VS Code é atualizado pela nova imagem;
- host não precisa executar `dnf update code`.

---

# 43. CI em Pull Requests

Todo PR que afete imagem deve executar:

1. shell/static checks;
2. build OCI;
3. `bootc container lint`;
4. image invariants;
5. package/vendor checks;
6. secret/credential checks;
7. confirmar ausência de Bluefin/common/Brew/Docker/RPM Fusion.

Se custo permitir, também produzir QCOW2 somente em workflows específicos ou
em PRs marcados para integração.

Não gerar ISO em todo PR.

---

# 44. Build do canal testing

No merge elegível:

```text
build OCI
 ↓
checks
 ↓
push immutable digest
 ↓
tag testing
```

Registrar:

- Git SHA;
- Silverblue base digest;
- image digest final;
- data UTC;
- Fedora release;
- versão `code`.

---

# 45. Promoção stable

Promoção não deve alterar o conteúdo.

Ela deve apontar `stable` para o digest previamente validado.

Antes da promoção:

- testing existe;
- digest é conhecido;
- CI do commit correspondente passou;
- invariantes passaram;
- não é o mesmo digest já stable;
- gate de 14 dias passou OU execução é emergency/manual.

Depois:

- mover tag `stable`;
- criar checksum/metadata;
- opcionalmente GitHub Release enxuta;
- preservar histórico de digest.

---

# 46. Rollback e rastreabilidade

Nunca depender apenas da tag `stable`.

Registrar digests anteriores.

Manter informação suficiente para:

```text
current stable digest
previous stable digest
source commit
base Silverblue digest
build date
```

O objetivo é facilitar:

- rollback bootc;
- investigação;
- comparação;
- reprodução.

Não apagar imagens antigas agressivamente.

Definir política de retenção depois.

---

# 47. Assinatura

Se Pinguim/Akatsuki já possuem fluxo de cosign validado, reaproveitar apenas se
ele estiver correto e simples.

Não inventar nova PKI desnecessária.

Se usar cosign:

- assinar digest, não apenas tag;
- CI deve falhar se assinatura obrigatória falhar;
- documentar origem da chave/identity;
- não embutir chave privada.

Se a assinatura existente depende de fluxo GitHub OIDC/keyless e já funciona,
preferir reaproveitá-lo.

---

# 48. SBOM/proveniência

Se Finpilot atual já fornece SBOM/provenance de maneira genérica e sem puxar
componentes Bluefin para runtime, manter.

Caso contrário, não transformar SBOM em bloqueador da v0.1.

Prioridade:

1. imagem correta;
2. digest;
3. assinatura;
4. checks;
5. depois enriquecimento de metadata.

---

# 49. ISO

Não trabalhar na ISO antes da OCI Kobold estar validada.

Fluxo:

```text
OCI
 ↓
QCOW2
 ↓
VM
 ↓
ISO
 ↓
VM instalação
 ↓
T495
```

A ISO deve instalar o payload Kobold validado.

Não colocar Anaconda permanentemente na imagem Kobold.

Usar Image Builder/osbuild atual para ISO bootc quando chegar nessa etapa.

Separar:

```text
installer environment
payload Kobold
```

Preferir payload por digest e, se suportado pelo tooling atual, embutido na ISO.

---

# 50. Teste em QCOW2

Antes de ISO, validar:

- UEFI;
- GDM;
- GNOME;
- Niri;
- Software;
- Disks;
- Code;
- Podman;
- Distrobox;
- SELinux;
- firewall;
- ZRAM;
- TuneD;
- Bluetooth policy;
- virtualização quando possível;
- `pinguim doctor`.

---

# 51. Teste no ThinkPad T495

Depois de OCI/QCOW2/ISO aprovados.

Validar:

## Desktop

- GDM;
- GNOME;
- Niri;
- Nautilus;
- GNOME Software;
- GNOME Disks;
- Ptyxis;
- Text Editor;
- Loupe;
- Calculator.

## Hardware

- Wi-Fi;
- áudio;
- Bluetooth inicia OFF;
- toggle Bluetooth funciona;
- fingerprint;
- suspensão;
- wake;
- brilho;
- teclado;
- touchpad;
- webcam depois de instalar app apropriado.

## Dev

- VS Code Microsoft;
- git;
- gh;
- Podman rootless;
- Distrobox;
- QEMU/KVM;
- virt-manager.

## Segurança

```bash
getenforce
firewall-cmd --state
firewall-cmd --get-default-zone
bootc status
```

## Energia

Comparar com Pinguim:

- idle temperature;
- Firefox + VS Code;
- carga curta;
- fan behavior;
- bateria;
- suspend/wake.

Não aceitar regressão térmica relevante sem investigar.

---

# 52. Versão inicial v0.1

O escopo é somente:

```text
Fedora Silverblue oficial
Finpilot/build automation sem Bluefin runtime
GNOME mínimo
GNOME Software
GNOME Disks
Niri
VS Code Microsoft RPM
CLI mínima
Podman rootless
Distrobox
QEMU/KVM/libvirt
SELinux
firewalld drop / zero inbound
hardening Pinguim
TuneD/tuned-ppd Pinguim
Wi-Fi powersave off
audio powersave off
Bluetooth AutoEnable=false
fingerprint upstream
USB autosuspend upstream
ZRAM/memory tuning Pinguim
pinguim doctor
testing/stable
Renovate digest tracking
stable ~14 dias
emergency promotion manual
```

Nada além disso deve bloquear v0.1.

---

# 53. O que explicitamente NÃO fazer na v0.1

Não:

- importar Bluefin;
- importar `projectbluefin/common`;
- usar Brew/Homebrew;
- usar Bazaar;
- usar Docker;
- usar RPM Fusion;
- rebranding;
- custom GDM;
- custom Plymouth;
- custom wallpaper;
- preinstall Firefox;
- preinstall coleção de Flatpaks;
- DNS custom;
- updater próprio no host;
- reboot automático;
- VM autostart;
- swapfile extra;
- earlyoom;
- fail2ban;
- TLP;
- auto-cpufreq;
- USB autosuspend global off;
- fingerprint driver custom;
- dezenas de comandos `pinguim`;
- agente de IA embutido;
- hardening novo não validado;
- redução agressiva de pacotes;
- update Fedora major durante criação;
- ISO antes da OCI/VM funcionar.

---

# 54. Critério de aceite de uma customização

Cada delta em relação ao Silverblue precisa justificar ao menos um:

```text
segurança
estabilidade
eficiência
hardware
Dev/DevSecOps
manutenibilidade
```

Se a única justificativa for:

```text
“deixar mais custom”
“diminuir alguns MB”
“porque Akatsuki fazia”
“porque Finpilot oferece”
```

não entra.

---

# 55. Critério de sucesso da v0.1

A v0.1 está pronta quando:

```text
✓ base é Silverblue oficial por digest
✓ não há Bluefin/common no runtime
✓ build é reproduzível
✓ CI passa
✓ OCI passa bootc lint
✓ invariantes passam
✓ testing é publicado
✓ stable usa o mesmo digest testado
✓ Renovate acompanha base
✓ stable pode ser promovido após >=14 dias
✓ emergency promotion funciona manualmente
✓ host não atualiza/reinicia sozinho
✓ GNOME funciona
✓ Niri funciona
✓ VS Code Microsoft funciona
✓ Flatpak/GNOME Software funciona
✓ Firefox pode ser instalado manualmente
✓ Podman rootless funciona
✓ Distrobox funciona
✓ QEMU/KVM/libvirt funciona
✓ SELinux enforcing
✓ firewall fechado por padrão
✓ hardening do Pinguim preservado
✓ TuneD/tweaks térmicos preservados
✓ Bluetooth inicia OFF e toggle funciona
✓ fingerprint funciona upstream
✓ ZRAM/memory tuning funciona
✓ pinguim doctor funciona
✓ temperatura não regride de forma relevante no T495
```

---

# 56. Ordem de trabalho para o Codex

Executar nesta ordem:

```text
1. inspecionar Pinguim
2. inspecionar Akatsuki
3. inspecionar Finpilot upstream atual
4. documentar o que será reaproveitado
5. criar estrutura Kobold
6. fixar Silverblue por digest
7. portar hardening/tweaks Pinguim
8. criar seleção de pacotes/apps
9. configurar Niri
10. configurar VS Code
11. configurar Podman/Distrobox
12. configurar virtualização
13. criar pinguim doctor
14. criar static checks
15. criar image invariants
16. build OCI local
17. corrigir até OCI limpa
18. criar CI/GHCR testing
19. configurar Renovate
20. criar stable promotion gate
21. criar emergency manual promotion
22. validar QCOW2
23. documentar resultados
24. somente então preparar ISO
```

---

# 57. Regra de segurança operacional para o Codex

Não fazer mudanças destrutivas no GitHub sem solicitação explícita.

Durante desenvolvimento local:

- não apagar branches;
- não sobrescrever tags existentes;
- não substituir imagem stable antiga;
- não apagar packages;
- não apagar releases;
- não fazer `podman system reset`;
- não fazer prune global;
- não apagar projetos irmãos.

Antes de publicar primeira `stable`, apresentar claramente:

```text
base digest
Kobold digest
commit
checks
test results
```

---

# 58. Resumo executivo

Kobold deve funcionar assim:

```text
          Fedora Silverblue oficial
                    │
              digest pinning
                    │
                    ▼
                 Finpilot
          build / CI / Renovate
          sem Bluefin no runtime
                    │
                    ▼
                 Kobold
                    │
          ┌─────────┴─────────┐
          │                   │
       testing             stable
          │                   │
 cada integração        >=14 dias
 aprovada               ou emergência
          │                   │
          └─────────┬─────────┘
                    ▼
                 GHCR
                    │
                    ▼
              ThinkPad T495
                    │
             bootc upgrade
             quando desejado
```

Sistema:

```text
Fedora Silverblue
├── GNOME mínimo
├── GNOME Software
├── GNOME Disks
├── Niri
├── VS Code Microsoft
├── CLI Dev/DevSecOps mínima
├── Podman rootless
├── Distrobox
├── QEMU/KVM/libvirt
├── SELinux enforcing
├── firewalld default drop
├── hardening Pinguim
├── TuneD/tuned-ppd
├── Wi-Fi powersave off
├── audio powersave off
├── Bluetooth disponível / OFF no boot
├── fingerprint upstream
├── USB autosuspend upstream
├── ZRAM + memory tuning
└── pinguim doctor
```

A filosofia final é:

> **Fedora controla o sistema. Finpilot ajuda a operar a fábrica. Kobold mantém
> somente um delta pequeno, compreensível e já justificado.**
