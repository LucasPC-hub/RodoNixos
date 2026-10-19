# Limpeza automática de cache (vinda do repo do Matheus). O script só apaga
# unidades inteiras e antigas, e pula o que estiver em uso por algum processo:
# repos do Hugging Face, logs/cache do omp, cache do npm e cópias de staging
# abandonadas do Codex. A coleta de lixo do Nix fica em modules/core/nix.nix.
{ pkgs, ... }:

let
  cleanup = "${pkgs.python3}/bin/python3 ${./scripts/cache-cleanup.py}";

  # Units de usuário valem pra todo usuário; ConditionUser limita à laal.
  cleanupService = description: args: {
    inherit description;
    unitConfig.ConditionUser = "laal";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${cleanup} ${args}";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  cleanupTimer = description: timerConfig: {
    inherit description timerConfig;
    wantedBy = [ "timers.target" ];
    unitConfig.ConditionUser = "laal";
  };
in
{
  systemd.user.services.cache-cleanup =
    cleanupService "Limpa cache antigo do HuggingFace, omp e npm"
      "--npm ${pkgs.nodejs_22}/bin/npm cache";
  systemd.user.timers.cache-cleanup = cleanupTimer "Limpeza de cache a cada 30 min" {
    OnBootSec = "10min";
    OnUnitActiveSec = "30min";
  };

  # O Codex deixa cópias de staging em ~/.codex/.tmp (openai/codex#30794).
  systemd.user.services.codex-tmp-cleanup =
    cleanupService "Limpa staging abandonado do Codex" "codex-tmp";
  systemd.user.timers.codex-tmp-cleanup = cleanupTimer "Limpeza do staging do Codex a cada hora" {
    OnBootSec = "5min";
    OnUnitActiveSec = "1h";
  };

  # Logs do sistema limitados a 200 MB.
  services.journald.settings.Journal.SystemMaxUse = "200M";
}
