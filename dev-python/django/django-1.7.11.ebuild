# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

PYTHON_COMPAT=( python2_7 python3_4 pypy )
PYTHON_REQ_USE='sqlite?,threads(+)'
WEBAPP_NO_AUTO_INSTALL="yes"

inherit bash-completion-r1 distutils-r1 eutils versionator webapp

MY_P="Django-${PV}"

DESCRIPTION="High-level Python web framework"
HOMEPAGE="http://www.djangoproject.com/ https://pypi.python.org/pypi/Django"
SRC_URI="https://www.djangoproject.com/m/releases/$(get_version_component_range 1-2)/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS=""
IUSE="doc sqlite test"

RDEPEND=""
DEPEND="${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
	doc? ( >=dev-python/sphinx-1.0.7[${PYTHON_USEDEP}] )
	test? (
		$(python_gen_impl_dep sqlite)
		dev-python/docutils[${PYTHON_USEDEP}]
		dev-python/numpy[$(python_gen_usedep 'python*')]
		dev-python/pillow[${PYTHON_USEDEP}]
		dev-python/pytz[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		)"

#		dev-python/python-sqlparse[${PYTHON_USEDEP}]
#		dev-python/bcrypt[${PYTHON_USEDEP}]
#		dev-python/selenium[${PYTHON_USEDEP}]
#		sci-libs/gdal[geos,${PYTHON_USEDEP}]

S="${WORKDIR}/${MY_P}"

WEBAPP_MANUAL_SLOT="yes"

PATCHES=(
	"${FILESDIR}"/${PN}-1.7.6-bashcomp.patch
)

pkg_setup() {
	webapp_pkg_setup
}

python_prepare_all() {
	# Prevent d'loading in the doc build
	sed -e '/^    "sphinx.ext.intersphinx",/d' -i docs/conf.py || die

	distutils-r1_python_prepare_all
}

python_compile_all() {
	use doc && emake -C docs html
}

python_test() {
	# Tests have non-standard assumptions about PYTHONPATH,
	# and don't work with ${BUILD_DIR}/lib.
	PYTHONPATH=. "${PYTHON}" tests/runtests.py --settings=test_sqlite -v2 \
		|| die "Tests fail with ${EPYTHON}"
}

src_install() {
	distutils-r1_src_install
	webapp_src_install

	elog "Additional Backend support can be enabled via"
	optfeature "MySQL backend support in python 2.7 only" dev-python/mysql-python
	optfeature "MySQL backend support in python 2.7 - 3.4" dev-python/mysqlclient
	optfeature "PostgreSQL backend support" dev-python/psycopg:2
	optfeature "GEO Django" sci-libs/gdal[geos]
	optfeature "Memcached support" dev-python/pylibmc dev-python/python-memcached
	optfeature "ImageField Support" dev-python/pillow
	echo ""
}

python_install_all() {
	newbashcomp extras/django_bash_completion ${PN}-admin
	bashcomp_alias ${PN}-admin django-admin.py

	if use doc; then
		rm -fr docs/_build/html/_sources || die
		local HTML_DOCS=( docs/_build/html/. )
	fi

	insinto "${MY_HTDOCSDIR#${EPREFIX}}"
	doins -r django/contrib/admin/static/admin/.
	distutils-r1_python_install_all
}

pkg_postinst() {
	elog "A copy of the admin media is available to webapp-config for installation in a"
	elog "webroot, as well as the traditional location in python's site-packages dir"
	elog "for easy development."
	webapp_pkg_postinst
}
