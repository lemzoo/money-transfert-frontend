angular.module('app.views.aide', ['app.settings'])
	.controller 'ShowAideController', ($scope, session, SETTINGS) ->
		$scope.fileNameListForRole = []
		session.getUserPromise().then (user) ->
			userRole = user.role
			for fileName, roles of SETTINGS.FILENAME_GUIDE
				if '*' in roles or userRole in roles
					dotIndex = fileName.lastIndexOf(".")
					fileNameWithoutExtension = fileName.slice(0, dotIndex)
					$scope.fileNameListForRole.push({
						nameWithExtension: fileName,
						nameWithoutExtension: fileNameWithoutExtension
					})
