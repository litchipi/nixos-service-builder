{ pkgs, lib, src, version, ...}:
let
  python = pkgs.python310;
  pythonpkg = pkgs.python310Packages;
  pname = "mealie";
in
pythonpkg.buildPythonPackage rec {
  inherit pname version src;
  format = "pyproject";

  patches = [ ./mealie_statedir.patch ];

  nativeBuildInputs = [
    pythonpkg.poetry-core
  ];

  propagatedBuildInputs = with pythonpkg; [
    jinja2
    pillow
    pyyaml
    sqlalchemy
    aiofiles
    alembic
    aniso8601
    appdirs
    apprise
    bcrypt
    extruct
    fastapi
    gunicorn
    lxml
    orjson
    passlib
    psycopg2
    pyhumps
    recipe-scrapers
    uvicorn
    python-multipart
    python-slugify
    rapidfuzz
    python-dotenv
    python-jose
    ldap
    pytesseract

    # APScheduler
    # fastapi-camelcase
    # pathvalidate
    # requests
  ];

  disabledTestPaths = []; # TODO Skip single one instead of disabling checks
  doCheck = false; #true;
  checkInputs = with pythonpkg; [
    pytestCheckHook
  ];

  passthru = {
    inherit python pythonpkg;
    interpreter = "${python}/bin/python3";
    python_path = python.pkgs.makePythonPath propagatedBuildInputs;
  };

  meta = with lib; {
    description = "A Place for All Your Recipes";
    longDescription = ''
      Mealie is a self hosted recipe manager and meal planner with a RestAPI backend and a reactive frontend
      application built in Vue for a pleasant user experience for the whole family. Easily add recipes into your
      database by providing the url and mealie will automatically import the relevant data or add a family recipe with
      the UI editor.
    '';
    homepage = "https://nightly.mealie.io";
    license = licenses.agpl3;
    maintainers = with maintainers; [
      hexa
    ];
  };
}