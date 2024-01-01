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
    APScheduler
    aiofiles
    aniso8601
    appdirs
    apprise
    bcrypt
    extruct
    fastapi
    # fastapi-camelcase
    pyhumps
    alembic
    orjson
    pytesseract
    rapidfuzz
    gunicorn
    jinja2
    lxml
    passlib
    pathvalidate
    pillow
    psycopg2
    python-dotenv
    python-jose
    ldap
    python-multipart
    python-slugify
    pyyaml
    recipe-scrapers
    requests
    sqlalchemy
    uvicorn
  ];

  doCheck = true;
  checkInputs = with pythonpkg; [
    pytestCheckHook
  ];

  passthru = {
    python3 = pythonpkg;
    pythonPath = python.makePythonPath propagatedBuildInputs;
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
