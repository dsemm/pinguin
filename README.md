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
