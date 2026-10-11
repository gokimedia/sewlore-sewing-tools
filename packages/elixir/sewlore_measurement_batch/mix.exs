defmodule SewloreMeasurementBatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :sewlore_measurement_batch,
      version: "0.1.0",
      elixir: "~> 1.14",
      description:
        "Unit-explicit batch measurement validation with exact decimal tolerance checks",
      package: [
        licenses: ["MIT"],
        links: %{
          "Sewlore" => "https://sewlore.com/",
          "Methods guide" => "https://sewlore.com/pages/fabric-measurement-methods-guide"
        },
        files: ["lib", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md"]
      ],
      deps: [{:decimal, "~> 3.2"}, {:ex_doc, "~> 0.40.4", only: :dev, runtime: false}],
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"],
        homepage_url: "https://sewlore.com/",
        formatters: ["html"]
      ]
    ]
  end

  def application, do: [extra_applications: [:logger]]
end
