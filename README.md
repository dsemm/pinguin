# Pinguins x Focas

Protótipo original em Godot 4 para Android.

## Jogabilidade atual

- O pinguim fica subindo e descendo preso por cordas na catapulta.
- Toque na tela para lançar no timing desejado.
- Durante o voo, toque novamente para fazer o pinguim mergulhar.
- Derrube focas e quebre blocos de gelo.
- O personagem tem limite de quiques.
- A fase termina com vitória quando todas as focas são derrubadas ou derrota quando acabam os pinguins.

## Estrutura

```text
scenes/Main.tscn
scripts/Game.gd
export_presets.cfg
.github/workflows/build-android.yml
```

## Abrir no Godot

1. Instale Godot 4.6.x.
2. Abra a pasta do projeto.
3. Rode a cena principal `scenes/Main.tscn`.

## Exportar Android manualmente

1. No Godot, vá em `Project > Install Android Build Template...`.
2. Vá em `Project > Export...`.
3. Use o preset `Android APK` para testes.
4. Use o preset `Android AAB` para Play Store.
5. Troque o pacote `com.toxic.penguinsxseals` se desejar outro applicationId.

## GitHub Actions

O workflow `.github/workflows/build-android.yml` gera:

- APK debug para teste.
- AAB release para envio à Play Console.

Para assinar com sua chave real, adicione estes secrets no GitHub:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEYSTORE_PASSWORD`

Use a mesma senha para a keystore e para a chave/alias. O workflow também gera uma keystore temporária quando esses secrets não existem. Essa keystore temporária serve apenas para teste.


## Correção do GitHub Actions Android

O workflow `build-android.yml` já instala os export templates do Godot, configura o caminho do Android SDK/JDK e instala o Android build template do projeto antes de exportar. Isso corrige os erros comuns de `android_source.zip` ausente, `Android build template not installed` e `A valid Java SDK path is required`.

O splash/icon do projeto usa `assets/icon.png`, pois o boot splash do Godot exige PNG.

## v4 - Correção do build Android

- Corrigida a falha de parse do `scripts/Game.gd` no GitHub Actions.
- Variáveis locais que vinham de valores `Variant` agora têm tipagem explícita.
- Trocas principais: `normal: Vector2`, `target_camera: float`, `hp_ratio: float`, `alpha: float` e arrays tipados.
- O projeto também desativa `treat_warnings_as_errors` para evitar que warnings de CI interrompam o export Android.


## Correção v4

O workflow Android agora instala o Android build template manualmente extraindo `android_source.zip` em `android/build`, evitando falha silenciosa do comando `--install-android-build-template` em ambiente headless. Também detecta automaticamente `ANDROID_HOME` e `JAVA_HOME`, imprime os arquivos instalados e usa `set -euxo pipefail` nos passos críticos para mostrar a causa exata se uma nova falha acontecer.


## Correção v6

- `gradle_build/gradle_build_directory` agora aponta explicitamente para `res://android/build`.
- O workflow instala `platforms;android-35` e `build-tools;35.0.0`.
- O Android build template recebe `android/.gdignore` para não ser importado como recurso do projeto Godot.
- O preset Android inclui campos `keystore/*` vazios para usar os fallbacks por variáveis de ambiente do CI.
