# GitHub Actions Android build

Este projeto usa Godot 4.6.3 e gera dois artifacts:

- `pinguins-x-focas-debug-apk`
- `pinguins-x-focas-release-aab`

O workflow faz estes passos antes de exportar:

1. Instala dependências Linux, incluindo `libfontconfig1`.
2. Instala/copia os export templates do Godot para `$HOME/.local/share/godot/export_templates/4.6.3.stable`.
3. Configura `export/android/android_sdk_path` e `export/android/java_sdk_path` em `editor_settings-4.tres`.
4. Executa `godot --headless --path . --install-android-build-template --quit` para criar `android/build` no projeto.
5. Exporta APK debug e AAB release.

## Secrets opcionais para assinar o AAB

Configure no GitHub em `Settings > Secrets and variables > Actions`:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEYSTORE_PASSWORD`

O arquivo `.jks` precisa ser convertido para Base64 antes de salvar no secret:

```bash
base64 -w 0 upload-key.jks
```

Se os secrets não existirem, o workflow gera uma keystore temporária apenas para teste.
