{ inputs, ... }:

{
  imports = [ inputs.agent-skills.homeManagerModules.default ];

  programs.agent-skills = {
    enable = true;

    sources = {
      mattEngineering = {
        input = "mattpocock-skills";
        subdir = "skills/engineering";
      };
      mattInProgress = {
        input = "mattpocock-skills";
        subdir = "skills/in-progress";
      };
      mattMisc = {
        input = "mattpocock-skills";
        subdir = "skills/misc";
      };
      mattProductivity = {
        input = "mattpocock-skills";
        subdir = "skills/productivity";
      };
      natural-japanese = {
        input = "natural-japanese";
        subdir = "skills";
      };
      security-audit = {
        input = "security-audit-skill";
        subdir = "skills";
      };
    };

    skills = {
      enable = [
        "natural-japanese"
        "security-audit"
      ];
      enableAll = [
        "mattEngineering"
        "mattInProgress"
        "mattMisc"
        "mattProductivity"
      ];
    };

    targets.agents = {
      enable = true;
      structure = "link";
      dest = ".agents/skills";
    };
  };
}
