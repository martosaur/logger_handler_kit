defmodule LoggerHandlerKit.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/martosaur/logger_handler_kit"

  def project do
    [
      app: :logger_handler_kit,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Logger Handler Kit",
      docs: docs(),
      package: package()
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_env), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {LoggerHandlerKit.Application, []}
    ]
  end

  defp package do
    [
      description: "Your guide to Elixir logger handlers",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs() do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "guides/translation.md",
        "guides/unhandled.md",
        "guides/metadata.md"
      ],
      groups_for_modules: [
        Helpers: [
          LoggerHandlerKit.FakeStruct,
          LoggerHandlerKit.GenServer,
          LoggerHandlerKit.GenStatem,
          LoggerHandlerKit.Helper
        ]
      ],
      groups_for_extras: [
        Guides: Path.wildcard("guides/*.md")
      ],
      before_closing_head_tag: &before_closing_head_tag/1
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_ownership, "~> 1.0"},
      {:ex_doc, "~> 0.37", only: :dev}
    ]
  end

  defp before_closing_head_tag(:html) do
    """
    <script defer src="https://cdn.jsdelivr.net/npm/mermaid@11.6.0/dist/mermaid.min.js"></script>
    <script>
      let initialized = false;

      window.addEventListener("exdoc:loaded", () => {
        if (!initialized) {
          mermaid.initialize({
            startOnLoad: false,
            theme: document.body.className.includes("dark") ? "dark" : "default"
          });
          initialized = true;
        }

        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
            graphEl.innerHTML = svg;
            bindFunctions?.(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_head_tag(:epub), do: ""
end
